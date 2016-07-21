class MiqAutomateMigrator
  attr_reader :ae_domain_name
  attr_reader :migrations

  def initialize(ae_domain_name, migration_folder)
    @ae_domain_name = ae_domain_name
    @migrations = {}
    @migration_folder = migration_folder
    load_migrations
  end

  def migrate
    # TODO: look for missing migrations that have an earlier timestamp.
    puts "The last migration run was #{latest_timestamp}"
    puts "Applying the following migrations #{new_migrations.keys.sort.inspect}"

    # Go through all of the migrations in order.
    new_migrations.keys.sort.each do |timestamp|
      ActiveRecord::Base.transaction do
        migration = Object.const_get(migrations[timestamp])
        migration.up(ae_domain_name)
        record_migration(ae_domain_name, timestamp, migration)
      end
    end
  end

  private

  def new_migrations
    @migrations.select { |ts, _name| ts > latest_timestamp }
  end

  def load_migrations
    Dir.glob(File.join(@migration_folder, '*.rb')).each do |migration|
      require migration
      migration_file = File.basename(migration)
      timestamp = migration_file.split('_').first.to_i
      name = migration_file.gsub(/^\d+_/, '').gsub(/\.rb/, '')
      @migrations[timestamp] = name.split('_').map(&:capitalize).join
    end
  end

  def create_schema_migration_class(ae_domain_name)
    ns = MiqAeNamespace.find_or_create_by_fqname("/#{ae_domain_name}/Schema")
    # Create the class
    ns.ae_classes.create(name: 'Migrations')
  end

  def latest_timestamp
    migration_class = MiqAeClass.find_by_fqname("/#{ae_domain_name}/Schema/Migrations")

    if migration_class.nil?
      migration_class = create_schema_migration_class(ae_domain_name)
    end
    migration_class.ae_instances.map(&:name).sort.last.to_i
  end

  def record_migration(ae_domain_name, timestamp, migration)
    migration_class = MiqAeClass.find_by_fqname("/#{ae_domain_name}/Schema/Migrations")
    migration_class.ae_instances.create(name: timestamp)
    puts "Migration #{timestamp} #{migration} was run successfully."
  end
end

namespace :cbts do
  namespace :ae_domain do
    desc 'Apply domain migrations'
    task :migrate, [:ae_domain, :migration_dir] => [:environment] do |_, args|
      migrator = MiqAutomateMigrator.new(args[:ae_domain], args[:migration_dir])
      puts "Checking #{migrator.migrations.count} migrations against #{migrator.ae_domain_name}"
      migrator.migrate
    end
  end
end
