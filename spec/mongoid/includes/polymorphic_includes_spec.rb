require 'spec_helper'
require 'open3'
require 'rbconfig'
require 'securerandom'

describe Mongoid::Includes::Criteria do

  describe '#includes' do
    Given(:inclusions) { criteria.inclusions }

    context 'multiple inclusions through polymorphic associations' do
      Given(:pink_floyd) { Band.create!(name: 'Pink Floyd', musician_ids: [nil, '']) }
      Given(:jethro) { Band.create!(name: 'Jethro Tull') }
      Given {
        Artist.create!(name: 'David Gilmour', associated_act: pink_floyd)
        wywh = Album.create!(name: 'Wish You Were Here', release: Date.new(1975), owner: pink_floyd)
        Album.create!(name: 'The Dark Side of the Moon', release: Date.new(1973), owner: pink_floyd)

        Artist.create!(name: 'Ian Anderson', associated_act: jethro)
        standup = Album.create!(name: 'Stand Up', release: Date.new(1969), owner: jethro)
        Album.create!(name: 'Aqualung', release: Date.new(1971), owner: jethro)

        Song.create!(name: 'Shine On', album: wywh)
        Song.create!(name: 'We Used to Know', album: standup)
      }
      Given(:criteria) {
        Artist
          .includes(:musicians, from: :associated_act, from_class: Band)
          .includes(:associated_act, with: ->(bands) {
            bands
              .includes(:albums, with: ->(albums) { albums.gt(release: 1970) })
              .includes(:songs, from: :albums, with: ->(songs) { songs })
          })
      }

      describe ':with inclusions should not be overriden', skip: ENV["CI"] do
        When(:artists) { expect_query(4) { criteria.entries } } # There are no musicians, so no query should be made.
        Given(:albums) { artists.map(&:associated_act).flat_map(&:albums) }
        Then { artists.size == 2 }
        And {
          expect_no_queries { albums.size == 3 } # gt(release: 1970)
        }
        And {
          expect_no_queries { albums.flat_map(&:songs).size == 1 } # Only "Shine On"
        }
      end

      describe 'should not replace an includes with an specified modifier with a generic one' do
        Given(:inclusions) { new_criteria.inclusions.to_a }
        When(:new_criteria) { criteria.includes(:musicians, from: :associated_act, from_class: Band) }
        Then { inclusions.size == 2 }
        And  { inclusions.first.nested? }
        And  { inclusions.last.polymorphic? && inclusions.last.modifier }
      end

      it 'should fail if a polymorphic association is not disambiguated' do
        expect {
          criteria.includes(:musicians, from: :associated_act)
        }.to raise_error(Mongoid::Includes::Errors::InvalidPolymorphicIncludes)
      end
    end

    context 'eager loading polymorphic belongs_to associations with multiple concrete types' do
      before(:context) do
        class PolyRelated
          include Mongoid::Document
          store_in collection: :poly_relateds
        end

        class PolyMain
          include Mongoid::Document
          store_in collection: :poly_mains

          belongs_to :related, polymorphic: true, optional: true
        end

        class PolyTwo < PolyRelated
          has_one :parent, class_name: 'PolyMain', as: :related, inverse_of: :related
        end

        class PolyThree < PolyRelated
          has_one :parent, class_name: 'PolyMain', as: :related, inverse_of: :related
        end
      end

      after(:context) do
        %i[PolyMain PolyTwo PolyThree PolyRelated].each do |const|
          Object.send(:remove_const, const) if Object.const_defined?(const, false)
        end
      end

      it 'loads the related documents for each concrete type without raising' do
        PolyMain.create!(related: PolyTwo.create!)
        PolyMain.create!(related: PolyThree.create!)

        loaded = nil
        expect {
          loaded = PolyMain.includes(:related).entries
        }.not_to raise_error

        expect(loaded.map { |doc| doc.related.class }).to match_array([PolyTwo, PolyThree])

        expect {
          PolyMain.last.related.id
        }.not_to raise_error
      end
    end

    context 'polymorphic eager loading in a fresh Ruby process' do
      let(:project_root) { File.expand_path('../../..', __dir__) }

      it 'does not error when includes is evaluated from the CLI' do
        database_name = "mongoid_includes_spec_#{SecureRandom.hex(6)}"
        base_script = <<~RUBY
          require 'bundler/setup'
          require 'mongoid'
          require 'mongoid_includes'

          Mongoid.load_configuration(
            clients: {
              default: {
                database: '#{database_name}',
                hosts: %w[localhost:27017]
              }
            }
          )

          class Main
            include Mongoid::Document
            belongs_to :related, polymorphic: true, optional: true
          end

          class Related
            include Mongoid::Document
          end

          class Two < Related
            has_one :parent, as: :related
          end

          class Three < Related
            has_one :parent, as: :related
          end
        RUBY

        init_script = base_script + <<~RUBY
          client = Mongoid::Clients.default
          begin
            client.database.drop
          rescue Mongo::Error::OperationFailure
          end

          Main.destroy_all
          Related.destroy_all

          Main.create!(related: Two.create!)
          Main.create!(related: Three.create!)
        RUBY

        bad_script = base_script + <<~RUBY
          Main.includes(:related).entries
          Main.last.related.id

          Mongoid::Clients.default.database.drop
        RUBY

        run_script = lambda do |script|
          Open3.capture2e(
            { 'BUNDLE_GEMFILE' => File.join(project_root, 'Gemfile') },
            RbConfig.ruby,
            '-',
            chdir: project_root,
            stdin_data: script
          )
        end

        init_out, init_status = run_script.call(init_script)
        expect(init_status).to be_success, "failed to prepare polymorphic data: #{init_out}"

        bad_out, bad_status = run_script.call(bad_script)
        expect(bad_status).to be_success, "expected CLI reproduction to succeed, got #{bad_status.exitstatus}: #{bad_out}"
      end
    end
  end
end
