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

#include <cstdio>
#include <iostream>
#include <sstream>
#include <stdexcept>
#include <rl/hal/Dc1394Camera.h>

int
main(int argc, char** argv)
{
	try
	{
		rl::hal::Dc1394Camera dc1394(argc > 1 ? std::stoi(argv[1]) : 0);
		
		dc1394.open();
		dc1394.start();
		
		dc1394.setFramerate(rl::hal::Dc1394Camera::Framerate::f7_5);
		dc1394.setSpeed(rl::hal::Dc1394Camera::IsoSpeed::i400);
		dc1394.setVideoMode(rl::hal::Dc1394Camera::VideoMode::v1024x768_rgb8);
		
		dc1394.setFeatureMode(rl::hal::Dc1394Camera::Feature::gain, rl::hal::Dc1394Camera::FeatureMode::automatic);
		dc1394.setFeatureMode(rl::hal::Dc1394Camera::Feature::shutter, rl::hal::Dc1394Camera::FeatureMode::automatic);
		dc1394.setFeatureMode(rl::hal::Dc1394Camera::Feature::whiteBalance, rl::hal::Dc1394Camera::FeatureMode::automatic);
		
		std::vector<unsigned char> image(dc1394.getSize());
		
		for (unsigned int i = 0; i < 1; ++i)
		{
			dc1394.step();
			dc1394.grab(image.data());
			
			std::stringstream filename;
			filename << "image" << i << ".pgm";
			
			FILE* imagefile = fopen(filename.str().c_str(), "w");
			fprintf(imagefile, "P6\n%u %u\n255\n", dc1394.getWidth(), dc1394.getHeight());
			fwrite(image.data(), 1, image.size(), imagefile);
			fclose(imagefile);
		}
		
		dc1394.stop();
		dc1394.close();
	}
	catch (const std::exception& e)
	{
		std::cerr << e.what() << std::endl;
		return EXIT_FAILURE;
	}
	
	return EXIT_SUCCESS;
}
