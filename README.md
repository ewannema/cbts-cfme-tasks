# cbts-cfme-tasks

Scripts to ease management of a ManageIQ/CloudForms environment.

## Installation
Place the *.rake files in the /var/www/miq/vmdb/lib/tasks directory on your CFME
appliances.

## Commands

### rake cbts:ae_domain_migrate

In a standard deployment you may have a domain where your code resides and a
separate domain where you copy classes and create instances for configuration
data. This allows you to easily modify code while keeping the configuration
static.

Unfortunately this greatly complicates class schema changes. Instead of
requiring that someone manually make schema changes in the configuration domain
or delete and recreate it, you can write migrations in code that can be applied
to the configuration domain. This is handled similarly to how Rails performs
migrations.

All of the migrations should be in a single directory. Each migration is named
according to the following format ```timestamp_migration_class.rb``` where
timestamp is YearMonthDayHourMinutesSeconds ex 20160720143016 and the name of
the migration class is converted to snake case.

Migrations are applied in order of their timestamps and their application is
recorded in the domain under /Schema/Migrations. In subsequent runs, only
migrations newer than the last recorded migration will be run.

Migrations are currently written directly using Rails so be careful when
your write these. If there is enough interest we can implement a DSL
similar to that of Rails.

Rollbacks are currently not supported so in the case of an issue you should roll
forward to the previous schema.

**Example migration:**

```ruby
# cat migrations/20160720155945_remove_api_location_from_app_connection.rb
class RemoveApiLocationFromAppConnection
  def self.up(ae_domain_name)
    # Code to perform the migration goes in the up method.
    klass = MiqAeClass.find_by_fqname("/#{ae_domain_name}/Integration/App/Connection")
    klass.ae_fields.find { |f| f.name == 'api_location' }.destroy
  end
end
```

**Usage:**

```bash
cd /var/www/miq/vmdb
rake rake cbts:ae_domain:migrate[Config-Domain,/repository/migrations]
```
