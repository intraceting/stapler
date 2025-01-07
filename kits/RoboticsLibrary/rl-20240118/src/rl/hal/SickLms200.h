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

#ifndef RL_HAL_SICKLMS200_H
#define RL_HAL_SICKLMS200_H

#include <array>
#include <cstdint>

#include "CyclicDevice.h"
#include "Device.h"
#include "Lidar.h"
#include "Serial.h"

namespace rl
{
	namespace hal
	{
		/**
		 * Sick LMS 200 laser measurement system.
		 */
		class RL_HAL_EXPORT SickLms200 : public CyclicDevice, public Lidar
		{
		public:
			enum class BaudRate
			{
				/** 9,600 bps. */
				b9600,
				/** 19,200 bps. */
				b19200,
				/** 38,400 bps. */
#if defined(WIN32) || defined(__QNX__)
				b38400
#else // defined(WIN32) || defined(__QNX__)
				b38400,
				/** 500,000 bps. */
				b500000
#endif // defined(WIN32) || defined(__QNX__)
			};
			
			RL_HAL_DEPRECATED static constexpr BaudRate BAUDRATE_9600BPS = BaudRate::b9600;
			RL_HAL_DEPRECATED static constexpr BaudRate BAUDRATE_19200BPS = BaudRate::b19200;
#if defined(WIN32) || defined(__QNX__)
			RL_HAL_DEPRECATED static constexpr BaudRate BAUDRATE_38400BPS = BaudRate::b38400;
#else // defined(WIN32) || defined(__QNX__)
			RL_HAL_DEPRECATED static constexpr BaudRate BAUDRATE_38400BPS = BaudRate::b38400;
			RL_HAL_DEPRECATED static constexpr BaudRate BAUDRATE_500000BPS = BaudRate::b500000;
#endif // defined(WIN32) || defined(__QNX__)
			
			enum class Measuring
			{
				/** 8 meter. */
				m8,
				/** 16 meter. */
				m16,
				/** 32 meter. */
				m32,
				/** 80 meter. */
				m80,
				/** 160 meter. */
				m160,
				/** 320 meter. */
				m320
			};
			
			RL_HAL_DEPRECATED static constexpr Measuring MEASURING_8M = Measuring::m8;
			RL_HAL_DEPRECATED static constexpr Measuring MEASURING_16M = Measuring::m16;
			RL_HAL_DEPRECATED static constexpr Measuring MEASURING_32M = Measuring::m32;
			RL_HAL_DEPRECATED static constexpr Measuring MEASURING_80M = Measuring::m80;
			RL_HAL_DEPRECATED static constexpr Measuring MEASURING_160M = Measuring::m160;
			RL_HAL_DEPRECATED static constexpr Measuring MEASURING_320M = Measuring::m320;
			
			enum class Monitoring
			{
				continuous,
				single
			};
			
			RL_HAL_DEPRECATED static constexpr Monitoring MONITORING_CONTINUOUS = Monitoring::continuous;
			RL_HAL_DEPRECATED static constexpr Monitoring MONITORING_SINGLE = Monitoring::single;
			
			enum class Variant
			{
				/** Angle = 100 degrees, resolution = 0.25 degrees. */
				v100_25,
				/** Angle = 100 degrees, resolution = 0.5 degrees. */
				v100_50,
				/** Angle = 100 degrees, resolution = 1 degree. */
				v100_100,
				/** Angle = 180 degrees, resolution = 0.5 degrees. */
				v180_50,
				/** Angle = 180 degrees, resolution = 1 degree. */
				v180_100
			};
			
			RL_HAL_DEPRECATED static constexpr Variant VARIANT_100_25 = Variant::v100_25;
			RL_HAL_DEPRECATED static constexpr Variant VARIANT_100_50 = Variant::v100_50;
			RL_HAL_DEPRECATED static constexpr Variant VARIANT_100_100 = Variant::v100_100;
			RL_HAL_DEPRECATED static constexpr Variant VARIANT_180_50 = Variant::v180_50;
			RL_HAL_DEPRECATED static constexpr Variant VARIANT_180_100 = Variant::v180_100;
			
			/**
			 * @param[in] password String with 8 characters comprising "0...9", "a...z", "A...Z", and "_".
			 */
			SickLms200(
				const ::std::string& device = "/dev/ttyS0",
				const BaudRate& baudRate = BaudRate::b9600,
				const Monitoring& monitoring = Monitoring::single,
				const Variant& variant = Variant::v180_50,
				const Measuring& measuring = Measuring::m8,
				const ::std::string& password = "SICK_LMS"
			);
			
			virtual ~SickLms200();
			
			void close();
			
			void dumpConfiguration();
			
			void dumpStatus();
			
			BaudRate getBaudRate() const;
			
			::rl::math::Vector getDistances() const;
			
			::std::size_t getDistancesCount() const;
			
			::rl::math::Real getDistancesMaximum(const ::std::size_t& i) const;
			
			::rl::math::Real getDistancesMinimum(const ::std::size_t& i) const;
			
			Measuring getMeasuring() const;
			
			Monitoring getMonitoring() const;
			
			::rl::math::Real getResolution() const;
			
			::rl::math::Real getStartAngle() const;
			
			::rl::math::Real getStopAngle() const;
			
			::std::string getType();
			
			Variant getVariant() const;
			
			void open();
			
			void reset();
			
			void setBaudRate(const BaudRate& baudRate);
			
			void setMeasuring(const Measuring& measuring);
			
			void setMonitoring(const Monitoring& monitoring);
			
			void setVariant(const Variant& variant);
			
			void start();
			
			void step();
			
			void stop();
			
		protected:
			
		private:
			::std::uint16_t crc(const ::std::uint8_t* buf, const ::std::size_t& len) const;
			
			::std::size_t recv(::std::uint8_t* buf, const ::std::size_t& len, const ::std::uint8_t& command);
			
			void send(::std::uint8_t* buf, const ::std::size_t& len);
			
			bool waitAck();
			
			BaudRate baudRate;
			
			::std::uint8_t configuration;
			
			::std::array<::std::uint8_t, 812> data;
			
			BaudRate desired;
			
			Measuring measuring;
			
			Monitoring monitoring;
			
			::std::string password;
			
			Serial serial;
			
			Variant variant;
		};
	}
}

#endif // RL_HAL_SICKLMS200_H
