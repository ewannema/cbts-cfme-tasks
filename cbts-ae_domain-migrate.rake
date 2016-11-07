# Perform schema and instance migrations automatically.
class MiqAutomateMigrator
  attr_reader :ae_domain_name
  attr_reader :migrations

  def initialize(ae_domain_name, migration_folder)
    unless MiqAeDomain.find_by_name(ae_domain_name)
      raise "Domain not found: #{ae_domain_name}"
    end

    @ae_domain_name = ae_domain_name
    ensure_schema_migration_class_exists
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

  # Make all migrations as up to date without running them. Useful when bringing
  # an already deployed environment under control of Automate migrations.
  def mark_up_to_date
    @migrations.keys.sort.each do |timestamp|
      ActiveRecord::Base.transaction do
        migration = Object.const_get(migrations[timestamp])
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

  def ensure_schema_migration_class_exists
    ns = MiqAeNamespace.find_or_create_by_fqname("/#{ae_domain_name}/Schema")
    unless ns.ae_classes.find { |c| c.name == 'Migrations' }
      ns.ae_classes.create(name: 'Migrations')
    end
  end

  def latest_timestamp
    migration_class =
      MiqAeClass.find_by_fqname("/#{ae_domain_name}/Schema/Migrations")
    migration_class.ae_instances.map(&:name).sort.last.to_i
  end

  def record_migration(ae_domain_name, timestamp, migration)
    migration_class =
      MiqAeClass.find_by_fqname("/#{ae_domain_name}/Schema/Migrations")
    if migration_class.ae_instances.find { |i| i.name == timestamp.to_s }
      puts "Migration #{timestamp} #{migration} is already marked as executed."
    else
      migration_class.ae_instances.create(name: timestamp.to_s)
      puts "Migration #{timestamp} #{migration} is now marked as executed."
    end
  end
end

namespace :cbts do
  namespace :ae_domain do
    desc 'Apply domain migrations'
    task :migrate, [:ae_domain, :migration_dir] => [:environment] do |_, args|
      migrator = MiqAutomateMigrator.new(args[:ae_domain], args[:migration_dir])
      puts "Checking #{migrator.migrations.count} migrations against "\
           "#{migrator.ae_domain_name}"
      migrator.migrate
    end

    desc 'Mark all migrations as applied without running them.'
    task :mark_up_to_date, [:ae_domain, :migration_dir] => [:environment] do |_, args|
      migrator = MiqAutomateMigrator.new(args[:ae_domain], args[:migration_dir])
      puts "Marking #{migrator.migrations.count} migrations as applied "\
           "against #{migrator.ae_domain_name}"
      migrator.mark_up_to_date
    end
  end
end
