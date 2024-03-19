class NodesController < ApplicationController
  before_action :load_nodes, only: :common_ancestor

  def common_ancestor
    render json: @node_a.lowest_ancestor(other_node: @node_b), status: :ok
  end

  def birds
    render json: { bird_ids: bird_ids_from_nodes }, status: :ok
  end

  private

  def load_nodes
    @node_a = load_node
    if @node_a.nil?
      render json: { error: "Node not found" }, status: 404 and return
    end

    @node_b = load_node(param_name: :b)
    if @node_b.nil?
      render json: { error: "Node not found" }, status: 404 and return
    end
  end

  def load_node(param_name: :a)
    Node.find_by(id: params[param_name])
  end

  def bird_ids_from_nodes
    node_ids = Node.edge.map do |edge_node|
      selected_node_ids = edge_node.node_ids & node_ids_from_params
      if selected_node_ids.any?
        min_depth = Node.where(id: selected_node_ids).pluck(:depth).min - 1
        edge_node.node_ids[min_depth..]
      end
    end.flatten.uniq

    Bird.where(node_id: node_ids).pluck(:id)
  end

  def node_ids_from_params
    params[:node_ids].map(&:to_i)
  end
end
