# Handle priority ordering of automate domains.
class CbtsDomainOrdering
  def self.move_domain_above(moving_domain, above_domain)
    raise 'Can not move ManageIQ' if moving_domain == 'ManageIQ'

    # Reordering should not include the ManageIQ domain.
    domains = MiqAeDomain.order('priority DESC').reject { |d| d.name == 'ManageIQ' }

    moving_domain_idx = domains.index { |d| d.name == moving_domain }
    raise "Can not find moving domain #{moving_domain}" if moving_domain_idx.nil?
    moving = domains.delete_at(moving_domain_idx)

    above_domain_idx = domains.index { |d| d.name == above_domain }
    raise "Can not find the reference domain #{above_domain}" if above_domain_idx.nil?

    domains.insert(above_domain_idx, moving)

    MiqAeDomain.reset_priority_by_ordered_ids(domains.map(&:id).reverse)
  end

  def self.get_domain_below(domain_name)
    domains = MiqAeDomain.order('priority DESC').to_a
    domain_idx = domains.index { |d| d.name == domain_name }
    raise "Could not find the domain #{domain_name}." if domain_idx.nil?

    next_domain = domains[domain_idx + 1]
    next_domain.try(:name)
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
