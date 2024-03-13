class NodesController < ApplicationController
  def common_ancestor
    render json: node.lowest_ancestor(other_node: node(param_name: :b)), status: :ok
  end

  private

  def node(param_name: :a)
    Node.find(params[param_name])
  end
end
