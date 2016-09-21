# Handle priority ordering of automate domains.
class CbtsDomainOrdering
  def self.move_domain_above(moving_domain, above_domain)
    moving = MiqAeDomain.find_by_name(moving_domain)
    raise "Could not find the domain #{moving_domain}." unless moving
    raise 'Can not move a system domain' if moving.system

    tenant = moving.tenant
    tenant_domains = tenant.ae_domains.order('priority').to_a

    # Move the domain to the correct spot.
    tenant_domains.reject! { |d| d.id == moving.id }

    above_domain_idx = tenant_domains.index { |d| d.name == above_domain }
    if above_domain_idx.nil?
      raise "Can not find the reference domain #{above_domain}"
    end

    under_domain_idx = above_domain_idx + 1
    if tenant_domains[under_domain_idx].try(:system)
      raise 'Can not move a domain below a system domain.'
    end

    tenant_domains.insert(above_domain_idx + 1, moving)

    # As of 20160921 there is a bug in the MIQ code that reverses the order of
    # higher level tenants when a subtenant reorders their domains.
    # tenant.reset_domain_priority_by_ordered_ids(tenant_domains.map(&:id))

    # Priories are inconsistently applied depending on what domains
    # are visible to the person reordering them. Any domains that were
    # previously sorted were not re-ordered. Since that is the case I
    # figured we should just be able to order the ones for this tenant.
    tenant_domains.reject! { |d| d.name == MiqAeDatastore::MANAGEIQ_DOMAIN }
    MiqAeDomain.reset_priority_by_ordered_ids(tenant_domains)
  end

  def self.get_domain_below(domain_name)
    domain = MiqAeDomain.find_by_name(domain_name)
    raise "Could not find the domain #{domain_name}." unless domain

    tenant = domain.tenant
    domains = tenant.ae_domains.order('priority').to_a
    domain_idx = domains.index { |d| d.name == domain_name }

    prev_domain = domain_idx.zero? ? nil : domains[domain_idx - 1]
    prev_domain.try(:name)
  end
end

namespace :cbts do
  namespace :ae_domain do
    desc 'Move the priority of a domain above another.'
    task :reorder_above, [:domain_to_move, :above_domain] => [:environment] do |_, args|
      moving_domain = args[:domain_to_move]
      above_domain = args[:above_domain]
      puts "Placing #{moving_domain} above #{above_domain}"
      CbtsDomainOrdering.move_domain_above(moving_domain, above_domain)
    end

    desc 'Return the name of the domain below this one.'
    task :get_domain_below, [:ae_domain] => [:environment] do |_, args|
      puts CbtsDomainOrdering.get_domain_below(args[:ae_domain])
    end
  end
end
