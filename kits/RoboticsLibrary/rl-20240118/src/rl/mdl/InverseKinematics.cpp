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

#include "InverseKinematics.h"

namespace rl
{
	namespace mdl
	{
		InverseKinematics::InverseKinematics(Kinematic* kinematic) :
			goals(),
			kinematic(kinematic)
		{
		}
		
		InverseKinematics::~InverseKinematics()
		{
		}
		
		void
		InverseKinematics::addGoal(const Goal& goal)
		{
			this->goals.push_back(goal);
		}
		
		void
		InverseKinematics::addGoal(const ::rl::math::Transform& x, const ::std::size_t& i)
		{
			this->addGoal(::std::make_pair(x, i));
		}
		
		void
		InverseKinematics::clearGoals()
		{
			this->goals.clear();
		}
		
		const ::std::vector<InverseKinematics::Goal>&
		InverseKinematics::getGoals() const
		{
			return this->goals;
		}
	}
}
