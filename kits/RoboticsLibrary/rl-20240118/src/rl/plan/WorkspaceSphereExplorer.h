//
// Copyright (c) 2009, Markus Rickert
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// * Redistributions of source code must retain the above copyright notice,
//   this list of conditions and the following disclaimer.
// * Redistributions in binary form must reproduce the above copyright notice,
//   this list of conditions and the following disclaimer in the documentation
//   and/or other materials provided with the distribution.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
// CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.
//

#ifndef RL_PLAN_WORKSPACESPHEREEXPLORER_H
#define RL_PLAN_WORKSPACESPHEREEXPLORER_H

#include <list>
#include <random>
#include <set>
#include <boost/graph/adjacency_list.hpp>
#include <rl/math/AlignedBox.h>
#include <rl/math/Vector.h>

#include "WorkspaceSphere.h"
#include "WorkspaceSphereList.h"

namespace rl
{
	namespace plan
	{
		class DistanceModel;
		class Viewer;
		
		/**
		 * Wavefront expansion.
		 *
		 * Oliver Brock and Lydia E. Kavraki. Decomposition-based motion planning:
		 * A framework for real-time motion planning in high-dimensional configuration
		 * spaces. In Proceedings of the IEEE International Conference on Robotics
		 * and Automation, pages 1469-1474, 2001.
		 *
		 * http://dx.doi.org/10.1109/ROBOT.2001.932817
		 */
		class RL_PLAN_EXPORT WorkspaceSphereExplorer
		{
		public:
			enum class Greedy
			{
				distance,
				sourceDistance,
				space
			};
			
			RL_PLAN_DEPRECATED static constexpr Greedy GREEDY_DISTANCE = Greedy::distance;
			RL_PLAN_DEPRECATED static constexpr Greedy GREEDY_SOURCE_DISTANCE = Greedy::sourceDistance;
			RL_PLAN_DEPRECATED static constexpr Greedy GREEDY_SPACE = Greedy::space;
			
			WorkspaceSphereExplorer();
			
			virtual ~WorkspaceSphereExplorer();
			
			bool explore();
			
			const ::rl::math::AlignedBox3& getBoundingBox() const;
			
			::rl::math::Vector3* getGoal() const;
			
			Greedy getGreedy() const;
			
			DistanceModel* getModel() const;
			
			WorkspaceSphereList getPath() const;
			
			::rl::math::Real getRadius() const;
			
			::rl::math::Real getRange() const;
			
			::std::size_t getSamples() const;
			
			::rl::math::Vector3* getStart() const;
			
			Viewer* getViewer() const;
			
			bool isCovered(const ::rl::math::Vector3& point) const;
			
			void reset();
			
			void seed(const ::std::mt19937::result_type& value);
			
			void setBoundingBox(const ::rl::math::AlignedBox3& boundingBox);
			
			void setGoal(::rl::math::Vector3* goal);
			
			void setGreedy(const Greedy& greedy);
			
			void setModel(DistanceModel* model);
			
			void setRadius(const ::rl::math::Real& radius);
			
			void setRange(const ::rl::math::Real& range);
			
			void setSamples(const ::std::size_t& samples);
			
			void setStart(::rl::math::Vector3* start);
			
			void setViewer(Viewer* viewer);
			
			::rl::math::AlignedBox3 boundingBox;
			
			::rl::math::Vector3* goal;
			
			Greedy greedy;
			
			DistanceModel* model;
			
			::rl::math::Real radius;
			
			::rl::math::Real range;
			
			::std::size_t samples;
			
			::rl::math::Vector3* start;
			
			Viewer* viewer;
			
		protected:
			struct VertexBundle
			{
				WorkspaceSphere sphere;
			};
			
			typedef ::boost::adjacency_list<
				::boost::listS,
				::boost::listS,
				::boost::bidirectionalS,
				VertexBundle
			> Graph;
			
			typedef ::boost::graph_traits<Graph>::edge_descriptor Edge;
			
			typedef ::boost::graph_traits<Graph>::edge_iterator EdgeIterator;
			
			typedef ::std::pair<EdgeIterator, EdgeIterator> EdgeIteratorPair;
			
			typedef ::boost::graph_traits<Graph>::vertex_descriptor Vertex;
			
			typedef ::boost::graph_traits<Graph>::vertex_iterator VertexIterator;
			
			typedef ::std::pair<VertexIterator, VertexIterator> VertexIteratorPair;
			
			Edge addEdge(const Vertex& u, const Vertex& v);
			
			Vertex addVertex(const WorkspaceSphere& sphere);
			
			bool isCovered(const Vertex& parent, const ::rl::math::Vector3& point) const;
			
			::std::uniform_real_distribution<::rl::math::Real>::result_type rand();
			
			Vertex begin;
			
			Vertex end;
			
			Graph graph;
			
			::std::multiset<WorkspaceSphere> queue;
			
			::std::uniform_real_distribution<::rl::math::Real> randDistribution;
			
			::std::mt19937 randEngine;
			
		private:
			
		};
	}
}

#endif // RL_PLAN_WORKSPACESPHEREEXPLORER_H
