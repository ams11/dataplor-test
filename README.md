# README

dataplor skill test: https://docs.google.com/document/d/1ALjDdMDGZ_yKs9AFI4A6BaSFPX1qzPF2TJ9FAnXVUDk/edit

The project is build with Ruby 3.0.0 and Rails 7, using Minitest for running unit tests. To get started, run:
- `bundle exec` to install all the gems
- `rails s` to start the server. Access it at http://localhost:3000
- `rails c` to launch the console
- `ruby -Itest [path to test file]` to run a test

There are no db seeds for the production environment - I've used the Rails console to create sample data locally. The tests generate their own fixtures needed for individual tests.

## Design and Functionality

**Models**: I've modeled the data structures needed with `Node` and `Bird` models. `Node`'s work as a tree, with each `Node` having one parent and 0 or more child `Node`'s. `Bird`'s, similarly `belong_to` `Node`'s, while a `Node` `has_many` `Bird`'s.

The approach I took was to pre-process the Node data via a Depth-First traversal of the tree (see `Node#index_nodes!`). I've added a `node_ids` column to the `nodes` table - it will only be populated for edge nodes (Nodes that do not have any children) and will contain the full list of nodes that traces the tree from the edge all the way to its head (root) node.
Pre-caching the full list of nodes allows for an O(1) comparison at run time when finding a common ancestor for any two nodes. If the nodes have the same root node, there must be an overlap somewhere in their trees. `Bird` lookup is slighly more complicated, as I'm iterating over all the Edge nodes (`NodesController#bird_ids_from_nodes`) to find all the paths that lead from an edge to any of the Nodes given in the input.
The difference is effectively that for common ancestors, we are only looking up the tree, where the branches collapse, limiting the number of possible matches. For the bird relationships however, we have to trace down the tree from the given set of input nodes, where the number of possible paths down to all the edges can expand exponentially.

For supporting new data being added at run time, I've added the logic in `Node#node_id_list` to support having partial node id lists. Effectively, when new data is added, we will eventually want to re-index the entire dataset to re-build the full indexes. In the interim, however, we can do an incremental index: we can build a node list for the tree starting from the old (pre-addition) edge nodes leading to the new edges: `Node#index_new_nodes!`.
Then when looking up the data and building up the node lists, we don't simply assume that the new edge nodes will have the entire list of node id's leading all the way to the root - instead the list may only lead to another edge node, which would have its own list of node_id's leading up to the root node (or another intermittent edge node).
This will affect the lookup performance - the worst case would be a if a large number of Node's were added one at a time, creating a long tree where each node is an intermediate edge, so we'd have to traverse each one of them from the outer edge all the way to the root in order to get an accurate node list.
Hopefully, such a case is unlikely, and if it were to happen, the problem would be resolved the next time we do a full re-index of the data set, which would ideally happen after every addition of Nodes. If we do expect to have a lot of small batches of new nodes being added, we could queue them up and combine them into larger batches to better optimize lookup performance at the expense of new data not being immediately available. 

This solution will support large datasets, but with an expensive pre-processing step. For a production system, it may be worth exploring different database structures that may be better optimized for handling large, tree-shaped data sets. I focused my solution around a standard relational database, however, in a production system a different approach, such as a NoSQL database, or perhaps a structure like a Spanner database (Used at Google for their Authorization system: https://www.aserto.com/blog/google-zanzibar-drive-rebac-authorization-model) might offer a better solution.  