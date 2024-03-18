class Node < ApplicationRecord
  belongs_to :parent, class_name: Node.to_s, foreign_key: :parent_node_id, optional: true
  has_many :children, class_name: Node.to_s, foreign_key: :parent_node_id
  belongs_to :edge, class_name: Node.to_s, optional: true, foreign_key: :edge_node_id

  scope :roots, -> { where(parent_node_id: nil) }
  scope :edge, -> { where(id: Node.pluck(:edge_node_id).uniq) }

  def lowest_ancestor(other_node:)
    return { root_id: root_node_id, lowest_common_ancestor: id, depth: depth } if other_node == self
    return { root_id: nil, lowest_common_ancestor: nil, depth: nil } unless root_node_id == other_node.root_node_id

    node_ids = edge.node_id_list.slice(0..depth-1)
    other_node_ids = other_node.edge.node_id_list.slice(0..other_node.depth-1)
    common_ids = node_ids & other_node_ids
    ancestor = Node.find(common_ids.last)
    { root_id: common_ids.first, lowest_common_ancestor: ancestor.id, depth: ancestor.depth }
  end

  def root_node_id
    return nil if edge.nil? || edge.node_id_list.blank?

    edge.node_id_list.first
  end

  def node_id_list
    return @node_id_list if defined? @node_id_list

    @node_id_list = edge.node_ids
    root_node = Node.find(@node_id_list.first)
    while root_node.parent_node_id
      parent_node = Node.find(root_node.parent_node_id)
      @node_id_list = @node_id_list.prepend(parent_node.node_ids).flatten
      root_node = Node.find(parent_node.node_ids.first)
    end

    @node_id_list
  end

  # index all the Node's from the very top root Node's
  def self.index_nodes!(instrument_time: false)
    start_time = Time.now if instrument_time

    index_root_nodes!(Node.roots.includes(:children))

    if instrument_time
      time_diff = Time.now - start_time
      puts "Elapsed time for #index_node!: #{time_diff} seconds"
    end
  end

  def self.index_new_nodes!
    # if new Nodes have been added to our, then the current edge Node's
    # will now have children, so we can treat each edge Node as a root and
    # index all the children of each edge.
    # #node_id_list is already capable of combining node_id lists when an edge
    # Node has children.
    index_root_nodes!(Node.edge.includes(:children))
  end

  def self.index_root_nodes!(root_nodes)
    root_nodes.each do |node|
      head_nodes = { [] => [node] }
      while head_nodes.any?
        node_ids, heads = head_nodes.shift
        heads.each do |head_node|
          head_node_ids = node_ids.dup
          while head_node.children.any?
            node_ids << head_node.id
            head_nodes[node_ids.dup] = head_node.children[1..]
            head_node = head_node.children.first
          end
          node_ids << head_node.id
          head_node.update(node_ids: node_ids)

          Node.where(id: node_ids).update_all(edge_node_id: head_node.id)
          depths = node_ids.map.each_with_index { |_, index| { depth: index+1 } }
          Node.update(node_ids, depths)
          node_ids = head_node_ids
        end
      end
    end
  end
end
