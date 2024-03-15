require "test_helper.rb"

class NodesControllerTest < ActionDispatch::IntegrationTest
  describe "/common_ancestor" do
    it "returns 404 if params not specified" do
      get common_ancestor_url
      assert_response :not_found
    end

    it "returns 404 if one of the params is missing" do
      node = Node.create
      get common_ancestor_nodes_url, params: { a: node.id }
      assert_response :not_found
    end

    it "returns 404 if nodes don't exist" do
      get common_ancestor_nodes_url, params: { a: "123", b: "456" }
      assert_response :not_found
    end

    it "returns 404 if one of the nodes doesn't exist" do
      node = Node.create
      get common_ancestor_nodes_url, params: { a: node.id, b: "invalid" }
      assert_response :not_found
    end

    it "returns the common node for valid nodes" do
      root_node = Node.create
      child1 = Node.create(parent_node_id: root_node.id)
      child2 = Node.create(parent_node_id: root_node.id)
      Node.index_nodes!

      get common_ancestor_nodes_url, params: { a: child1.id, b: child2.id }
      assert_response :success
      expected_result = { "root_id" => root_node.id, "lowest_common_ancestor" => root_node.id, "depth" => 1 }
      result = JSON.parse response.body
      assert_equal expected_result, result
    end

    it "returns success, but null values if there is no common ancestor" do
      node1 = Node.create
      node2 = Node.create
      Node.index_nodes!

      get common_ancestor_nodes_url, params: { a: node1.id, b: node2.id}
      assert_response :success
      expected_result = { "root_id" => nil, "lowest_common_ancestor" => nil, "depth" => nil }
      result = JSON.parse response.body
      assert_equal expected_result, result
    end

    it "works for the /nodes/common_ancestor url as well" do
      root_node = Node.create
      child1 = Node.create(parent_node_id: root_node.id)
      child2 = Node.create(parent_node_id: root_node.id)
      Node.index_nodes!

      get common_ancestor_nodes_url, params: { a: child1.id, b: child2.id }
      assert_response :success
      expected_result = { "root_id" => root_node.id, "lowest_common_ancestor" => root_node.id, "depth" => 1 }
      result = JSON.parse response.body
      assert_equal expected_result, result
    end
  end
end