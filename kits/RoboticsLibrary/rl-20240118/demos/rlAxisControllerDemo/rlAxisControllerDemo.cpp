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

#include <iostream>
#include <stdexcept>
#include <rl/hal/Coach.h>
#include <rl/hal/Gnuplot.h>
#include <rl/hal/MitsubishiH7.h>
#include <rl/hal/UniversalRobotsRtde.h>
#include <rl/math/Constants.h>
#include <rl/math/Polynomial.h>
#include <rl/math/Spline.h>

#define COACH
//#define GNUPLOT
//#define MITSUBISHI
//#define UNIVERSAL_ROBOTS_RTDE

//#define CUBIC
//#define QUINTIC
//#define SEPTIC
#define TRAPEZOIDAL

int
main(int argc, char** argv)
{
	try
	{
#ifdef COACH
		rl::hal::Coach controller(6, std::chrono::microseconds(7110), 0, "localhost");
#endif // COACH
#ifdef GNUPLOT
		rl::hal::Gnuplot controller(6, std::chrono::microseconds(7110), -10 * rl::math::constants::deg2rad, 10 * rl::math::constants::deg2rad);
#endif // GNUPLOT
#ifdef MITSUBISHI
		rl::hal::MitsubishiH7 controller(6, "left", "lefthost");
#endif // MITSUBISHI
#ifdef UNIVERSAL_ROBOTS_RTDE
		rl::hal::UniversalRobotsRtde controller("localhost");
#endif // UNIVERSAL_ROBOTS_RTDE
		
		rl::math::Real updateRate = std::chrono::duration_cast<std::chrono::duration<rl::math::Real>>(controller.getUpdateRate()).count();
		
		rl::math::Vector vmax = rl::math::Vector::Constant(controller.getDof(), 5 * rl::math::constants::deg2rad);
		rl::math::Vector amax = rl::math::Vector::Constant(controller.getDof(), 15 * rl::math::constants::deg2rad);
		rl::math::Vector jmax = rl::math::Vector::Constant(controller.getDof(), 45 * rl::math::constants::deg2rad);
		
		controller.open();
		controller.start();
		
		controller.step();
		
		rl::math::Vector q0 = controller.getJointPosition();
		rl::math::Vector q1 = q0 + rl::math::Vector::Constant(controller.getDof(), 5 * rl::math::constants::deg2rad);
		
		rl::math::Vector q(controller.getDof());
		
#ifdef CUBIC
		rl::math::Polynomial<rl::math::Vector> interpolator = rl::math::Polynomial<rl::math::Vector>::CubicAtRest(
#endif // CUBIC
#ifdef QUINTIC
		rl::math::Polynomial<rl::math::Vector> interpolator = rl::math::Polynomial<rl::math::Vector>::QuinticAtRest(
#endif // QUINTIC
#ifdef SEPTIC
		rl::math::Polynomial<rl::math::Vector> interpolator = rl::math::Polynomial<rl::math::Vector>::SepticAtRest(
#endif // SEPTIC
#ifdef TRAPEZOIDAL
		rl::math::Spline<rl::math::Vector> interpolator = rl::math::Spline<rl::math::Vector>::TrapezoidalAccelerationAtRest(
#endif // TRAPEZOIDAL
			q0,
			q1,
			vmax,
			amax,
			jmax
		);
		
		std::size_t steps = static_cast<std::size_t>(std::ceil(interpolator.duration() / updateRate)) + 1;
		
		for (std::size_t i = 0; i < steps; ++i)
		{
			q = interpolator(i * updateRate);
			controller.setJointPosition(q);
			controller.step();
		}
		
#ifdef CUBIC
		interpolator = rl::math::Polynomial<rl::math::Vector>::CubicAtRest(
#endif // CUBIC
#ifdef QUINTIC
		interpolator = rl::math::Polynomial<rl::math::Vector>::QuinticAtRest(
#endif // QUINTIC
#ifdef SEPTIC
		interpolator = rl::math::Polynomial<rl::math::Vector>::SepticAtRest(
#endif // SEPTIC
#ifdef TRAPEZOIDAL
		interpolator = rl::math::Spline<rl::math::Vector>::TrapezoidalAccelerationAtRest(
#endif // TRAPEZOIDAL
			q1,
			q0,
			vmax,
			amax,
			jmax
		);
		
		steps = static_cast<std::size_t>(std::ceil(interpolator.duration() / updateRate)) + 1;
		
		for (std::size_t i = 0; i < steps; ++i)
		{
			q = interpolator(i * updateRate);
			controller.setJointPosition(q);
			controller.step();
		}
		
		controller.stop();
		controller.close();
	}
	catch (const std::exception& e)
	{
		std::cerr << e.what() << std::endl;
		return EXIT_FAILURE;
	}
	
	return EXIT_SUCCESS;
}
