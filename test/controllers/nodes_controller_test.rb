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

  describe "/birds" do
    it "returns empty list if no param passed in" do
      get birds_url, params: { }

      assert_response :success
      result = JSON.parse response.body
      expected_result = { "bird_ids" => [] }
      assert_equal expected_result, result
    end

    it "returns empty list if no node id's passed in" do
      get birds_url, params: { node_ids: [] }

      assert_response :success
      result = JSON.parse response.body
      expected_result = { "bird_ids" => [] }
      assert_equal expected_result, result
    end

    it "returns all the bird id's for the given nodes" do
      root_node = Node.create
      child1 = Node.create(parent_node_id: root_node.id)
      child2 = Node.create(parent_node_id: root_node.id)
      child3 = Node.create(parent_node_id: root_node.id)
      [child1, child2].each do |child_node|
        5.times do
          node = Node.create(parent_node_id: child_node.id)
          rand(5).times do
            node = Node.create(parent_node_id: node.id)
          end
        end
      end
      bird1 = Bird.create(node_id: child1.id )
      bird2 = Bird.create(node_id: child2.id )
      bird3 = Bird.create(node_id: child3.id )
      bird1_1 = Bird.create(node_id: child1.children.last.id )
      bird1_1_1 = Bird.create(node_id: child1.children.first.children.last.id )
      Node.index_nodes!

      get birds_url, params: { node_ids: [child1.id, child2.id] }

      assert_response :success
      result = JSON.parse response.body
      expected_bird_ids = [bird1.id, bird2.id, bird1_1.id, bird1_1_1.id]
      assert_same_elements expected_bird_ids, result["bird_ids"]
    end

    it "returns no id's if no birds are attached to nodes in params" do
      root_node = Node.create
      child1 = Node.create(parent_node_id: root_node.id)
      child2 = Node.create(parent_node_id: root_node.id)
      child3 = Node.create(parent_node_id: root_node.id)
      [child1, child2].each do |child_node|
        5.times do
          node = Node.create(parent_node_id: child_node.id)
          rand(5).times do
            node = Node.create(parent_node_id: node.id)
          end
        end
      end
      Bird.create(node_id: child1.id )
      Bird.create(node_id: child2.id )
      Bird.create(node_id: child1.children.last.id )
      Bird.create(node_id: child1.children.first.children.last.id )
      Node.index_nodes!

      get birds_url, params: { node_ids: [child3.id] }

      assert_response :success
      result = JSON.parse response.body
      expected_result = { "bird_ids" => [] }
      assert_equal expected_result, result
    end
  end
end