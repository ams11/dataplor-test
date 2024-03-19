require 'minitest/autorun'
require "test_helper.rb"

class NodeTest < ActiveSupport::TestCase
  describe "initializer" do
    it "can create a valid Node and setup relationships" do
      parent_node = Node.create
      edge_node = Node.create
      node = Node.create(parent_node_id: parent_node.id, edge_node_id: edge_node.id)

      assert node.valid?
      assert_equal node.parent, parent_node.reload
      assert_equal node.edge, edge_node.reload
      assert_equal parent_node.children, [node]
    end
  end

  describe "roots scope" do
    it "returns nodes with no parent set" do
      parent_node = Node.create
      edge_node = Node.create
      node = Node.create(parent_node_id: parent_node.id, edge_node_id: edge_node.id)

      assert_same_elements Node.roots, [parent_node, edge_node]
      refute Node.roots.include? node
    end
  end

  describe "#lowest_ancestor" do
    before do
      NodeTest.create_large_node_tree(node_count: 50)
      Node.index_nodes!
    end

    it "finds the lowest common ancestor for two related nodes" do
      root_node = Node.roots.first
      first_child_node = root_node.children.first
      result = first_child_node.lowest_ancestor(other_node: first_child_node.children.last)
      expected_result = { root_id: root_node.id, lowest_common_ancestor: first_child_node.id, depth: first_child_node.depth }

      assert_equal expected_result, result
    end

    it "can find lowest common ancestor for edge nodes" do
      node1, node2 = Node.edge.sample(2)
      result = node1.lowest_ancestor(other_node: node2)
      assert_equal result[:root_id], Node.roots.first.id
      assert result[:lowest_common_ancestor]
      assert result[:depth]
    end

    it "returns the node if comparing to itself" do
      root_node = Node.roots.first
      node = root_node.children.first

      result = node.lowest_ancestor(other_node: node)
      expected_result = { root_id: root_node.id, lowest_common_ancestor: node.id, depth: node.depth }
      assert_equal expected_result, result
    end

    it "returns nil if the there is no common node" do
      node = Node.roots.first.children.first
      new_node = Node.create

      result = node.lowest_ancestor(other_node: new_node)
      expected_result = { root_id: nil, lowest_common_ancestor: nil, depth: nil }
      assert_equal expected_result, result
    end

    it "can include nodes that were just added and have only had a partial index" do
      parent_node1, parent_node2 = Node.edge.sample(2)
      new_node1 = Node.create(parent_node_id: parent_node1.id)
      new_node2 = Node.create(parent_node_id: new_node1.id)
      new_node3 = Node.create(parent_node_id: parent_node2.id)
      Node.index_new_nodes!  # index the new Nodes, without doing a full re-index

      result = new_node2.reload.lowest_ancestor(other_node: new_node3.reload)
      assert result[:root_id]
      assert result[:lowest_common_ancestor]
      assert result[:depth]
    end
  end

  describe "#index_nodes!" do
    before do
      NodeTest.create_large_node_tree(node_count: 250)
    end

    it "creates indices for all the Nodes" do
      assert_empty Node.where.not(edge_node_id: nil)
      Node.index_nodes!
      assert_empty Node.where(edge_node_id: nil)

      Node.edge.each do |edge_node|
        cached_edge_node = edge_node
        node_ids = [edge_node.id]
        while edge_node.parent
          node_ids << edge_node.parent_node_id
          edge_node = edge_node.parent
        end
        assert_same_elements cached_edge_node.node_ids, node_ids
        nodes = Node.where(id: node_ids)
        depths = node_ids.map.each_with_index { |_, index| index+1 }
        assert_equal nodes.map(&:depth), depths
      end
    end
  end

  describe "when working with a large dataset" do
    before do
      NodeTest.create_large_node_tree
    end

    it "succeeds" do
      assert_empty Node.where.not(edge_node_id: nil)
      Node.index_nodes!
      assert_empty Node.where(edge_node_id: nil)
    end
  end

  def self.create_large_node_tree(node_count: 1_000, root_node: Node.create)
    child_count = rand(1..5)
    # puts "node count: #{node_count}, child count: #{child_count}, next node count: #{node_count / child_count}"
    node_count = node_count / child_count
    child_count.times do
      node = Node.create(parent_node_id: root_node.id)
      create_large_node_tree(node_count: node_count, root_node: node) if node_count > child_count
    end
  end
end
