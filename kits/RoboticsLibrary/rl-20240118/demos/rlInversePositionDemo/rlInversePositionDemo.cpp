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

#include <chrono>
#include <iostream>
#include <memory>
#include <stdexcept>
#include <boost/lexical_cast.hpp>
#include <rl/hal/Coach.h>
#include <rl/math/Constants.h>
#include <rl/mdl/Kinematic.h>
#include <rl/mdl/JacobianInverseKinematics.h>
#include <rl/mdl/UrdfFactory.h>
#include <rl/mdl/XmlFactory.h>

#ifdef RL_MDL_NLOPT
#include <rl/mdl/NloptInverseKinematics.h>
#endif

#define COACH

int
main(int argc, char** argv)
{
	if (argc < 2)
	{
		std::cout << "Usage: rlInversePositionDemo MODELFILE Q1 ... Qn" << std::endl;
		return EXIT_FAILURE;
	}
	
	try
	{
		std::string filename(argv[1]);
		std::shared_ptr<rl::mdl::Kinematic> kinematic;
		
		if ("urdf" == filename.substr(filename.length() - 4, 4))
		{
			rl::mdl::UrdfFactory factory;
			kinematic = std::dynamic_pointer_cast<rl::mdl::Kinematic>(factory.create(filename));
		}
		else
		{
			rl::mdl::XmlFactory factory;
			kinematic = std::dynamic_pointer_cast<rl::mdl::Kinematic>(factory.create(filename));
		}
		
		rl::math::Vector q(kinematic->getDof());
		
		for (std::ptrdiff_t i = 0; i < q.size(); ++i)
		{
			q(i) = boost::lexical_cast<rl::math::Real>(argv[i + 2]);
		}
		
		kinematic->setPosition(q);
		
		kinematic->forwardPosition();
		rl::math::Vector3 position = kinematic->getOperationalPosition(0).translation();
		rl::math::Vector3 orientation = kinematic->getOperationalPosition(0).rotation().eulerAngles(2, 1, 0).reverse();
		std::cout << "x: " << position.x() << " m, y: " << position.y() << " m, z: " << position.z() << " m, a: " << orientation.x() * rl::math::constants::rad2deg << " deg, b: " << orientation.y() * rl::math::constants::rad2deg << " deg, c: " << orientation.z() * rl::math::constants::rad2deg << " deg" << std::endl;
		
#ifdef RL_MDL_NLOPT
		rl::mdl::NloptInverseKinematics ik(kinematic.get());
		std::cout << "IK using rl::mdl::NloptInverseKinematics";
#else
		rl::mdl::JacobianInverseKinematics ik(kinematic.get());
		std::cout << "IK using rl::mdl::JacobianInverseKinematics";
#endif
		ik.setDuration(std::chrono::seconds(1));
		std::cout << " with timeout of " << std::chrono::duration_cast<std::chrono::milliseconds>(ik.getDuration()).count() << " ms" << std::endl;
		ik.addGoal(kinematic->getOperationalPosition(0), 0);
		
		q = kinematic->generatePositionUniform();
		kinematic->setPosition(q);
		
		std::chrono::steady_clock::time_point start = std::chrono::steady_clock::now();
		bool result = ik.solve();
		std::chrono::steady_clock::time_point stop = std::chrono::steady_clock::now();
		std::cout << (result ? "true" : "false") << " " << std::chrono::duration_cast<std::chrono::duration<double>>(stop - start).count() * 1000 << " ms" << std::endl;
		
		kinematic->forwardPosition();
		position = kinematic->getOperationalPosition(0).translation();
		orientation = kinematic->getOperationalPosition(0).rotation().eulerAngles(2, 1, 0).reverse();
		std::cout << "x: " << position.x() << " m, y: " << position.y() << " m, z: " << position.z() << " m, a: " << orientation.x() * rl::math::constants::rad2deg << " deg, b: " << orientation.y() * rl::math::constants::rad2deg << " deg, c: " << orientation.z() * rl::math::constants::rad2deg << " deg" << std::endl;
		
		std::cout << "q: " << kinematic->getPosition().transpose() << std::endl;
		
#ifdef COACH
		rl::hal::Coach controller(kinematic->getDof(), std::chrono::milliseconds(1), 0, "localhost");
		controller.open();
		controller.start();
		controller.setJointPosition(kinematic->getPosition());
		controller.step();
		controller.stop();
		controller.close();
#endif // COACH
	}
	catch (const std::exception& e)
	{
		std::cout << e.what() << std::endl;
		return EXIT_FAILURE;
	}
	
	return EXIT_SUCCESS;
}
