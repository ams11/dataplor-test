class Node < ApplicationRecord
  belongs_to :parent, class_name: Node.to_s, foreign_key: :parent_node_id, optional: true
  has_many :children, class_name: Node.to_s, foreign_key: :parent_node_id
  belongs_to :edge, class_name: Node.to_s, optional: true, foreign_key: :edge_node_id

  scope :roots, -> { where(parent_node_id: nil) }

  def lowest_ancestor(other_node:)
    return { root_id: root_node.id, lowest_common_ancestor: self, depth: depth } if other_node == self
    return { root_id: nil, lowest_common_ancestor: nil, depth: nil } unless root_node == other_node.root_node

    node_ids = edge.node_ids.slice(0..edge.node_ids.index(id))
    other_node_ids = other_node.edge.node_ids.slice(0..other_node.edge.node_ids.index(other_node.id))
    common_ids = node_ids & other_node_ids
    ancestor = Node.find(common_ids.last)
    { root_id: common_ids.first, lowest_common_ancestor: ancestor.id, depth: ancestor.depth }
  end

  def root_node
    return nil if edge.nil? || edge.node_ids.blank?

    Node.find(edge.node_ids.first)
  end

  def self.index_nodes!
    Node.roots.includes(:children).each do |node|
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
