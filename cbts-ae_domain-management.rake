# Basic automate domain management tasks.
class CbtsDomainManagement
  def self.enabled?(domain_name)
    domain = MiqAeDomain.find_by_name(domain_name)
    raise "Could not find the domain #{domain_name}." if domain.nil?

    domain.enabled
  end

  def self.enable(domain_name)
    domain = MiqAeDomain.find_by_name(domain_name)
    raise "Could not find the domain #{domain_name}." if domain.nil?

    domain.enabled = true
    domain.save
  end

  def self.disable(domain_name)
    domain = MiqAeDomain.find_by_name(domain_name)
    raise "Could not find the domain #{domain_name}." if domain.nil?

    domain.enabled = false
    domain.save
  end

  def self.list_domains
    MiqAeDomain.order('priority DESC').map(&:name)
  end

  def self.exists?(domain_name)
    MiqAeDomain.find_by_name(domain_name) ? true : false
  end

  def self.rename(domain_name, new_domain_name)
    domain = MiqAeDomain.find_by_name(domain_name)
    raise "Could not find the domain #{domain_name}." if domain.nil?

    domain.name = new_domain_name
    raise 'Unable to rename the domain.' unless domain.save

    new_domain_name
  end

  def self.create(domain_name, tenant_name)
    raise 'Domain already exists' if MiqAeDomain.find_by_name(domain_name)

    # Tenant find_by_name does not work for the root customer. It seems to have
    # the name My Company, but that is sometimes replaced by the renamed text.
    tenant = Tenant.all.find { |t| t.name == tenant_name }
    raise "Tenant #{tenant_name} not found." unless tenant

    priority = MiqAeDomain.where(tenant: tenant).map(&:priority).max.to_i + 1

    if (MiqAeDomain.new.respond_to?(:system))
      MiqAeDomain.create!(name: domain_name, system: false, enabled: false,
                          tenant: tenant, priority: priority)
    else
      MiqAeDomain.create!(name: domain_name, source: MiqAeDomain::USER_SOURCE,
                          enabled: false, tenant: tenant, priority: priority)
    end
  end

  def self.destroy(domain_name)
    domain = MiqAeDomain.find_by_name(domain_name)
    raise "Could not find the domain #{domain_name}." if domain.nil?

    domain.destroy
  end
end

namespace :cbts do
  namespace :ae_domain do
    desc 'List the automate domains in priority order.'
    task :list => [:environment] do
      CbtsDomainManagement.list_domains.each { |d| puts d }
    end

    desc 'Rename the automate domain.'
    task :rename, [:ae_domain, :new_name] => [:environment] do |_, args|
      CbtsDomainManagement.rename(args[:ae_domain], args[:new_name])
    end

    desc 'Create an empty automate domain.'
    task :create, [:ae_domain, :tenant_name] => [:environment] do |_, args|
      CbtsDomainManagement.create(args[:ae_domain], args[:tenant_name])
    end

    desc 'Delete the automate domain.'
    task :delete, [:ae_domain] => [:environment] do |_, args|
      CbtsDomainManagement.destroy(args[:ae_domain])
    end

    desc 'Determine if the domain is enabled.'
    task :is_enabled, [:ae_domain] => [:environment] do |_, args|
      puts CbtsDomainManagement.enabled?(args[:ae_domain])
    end

    desc 'Determine if the domain exists.'
    task :exists, [:ae_domain] => [:environment] do |_, args|
      puts CbtsDomainManagement.exists?(args[:ae_domain])
    end

    desc 'Enable the automate domain.'
    task :enable, [:ae_domain] => [:environment] do |_, args|
      domain_name = args[:ae_domain]
      CbtsDomainManagement.enable(domain_name)

      if CbtsDomainManagement.enabled?(domain_name)
        puts "Domain #{domain_name} is enabled."
      else
        raise "Unable to enable #{domain_name}."
      end
    end

    desc 'Disable the automate domain.'
    task :disable, [:ae_domain] => [:environment] do |_, args|
      domain_name = args[:ae_domain]
      CbtsDomainManagement.disable(args[:ae_domain])

      if CbtsDomainManagement.enabled?(domain_name)
        raise "Unable to disable #{domain_name}."
      else
        puts "Domain #{domain_name} is disabled."
      end
    end
  end
end
