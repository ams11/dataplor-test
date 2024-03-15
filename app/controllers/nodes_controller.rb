class NodesController < ApplicationController
  before_action :load_nodes, only: :common_ancestor

  def common_ancestor
    render json: @node_a.lowest_ancestor(other_node: @node_b), status: :ok
  end

  def birds
    render json: bird_ids_from_nodes, status: :ok
  end

  private

  def load_nodes
    @node_a =  load_node
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
    nodes = Node.includes(:edge).where(id: params[:node_ids]).index_by(&:root_node_id)
    node_ids = []
    nodes.each do |_, nodes|
      min_depth_index = nodes.pluck(:depth).min-1
      node_ids << nodes.first.edge.node_ids.slice(min_depth_index..)
    end
    Bird.where(node_id: node_ids)
  end
end
