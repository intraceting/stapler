//
// Copyright (c) 2009, Andre Gaschler
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

#include <rl/math/Constants.h>
#include <rl/mdl/Kinematic.h>
#include <rl/mdl/Revolute.h>
#include <rl/sg/Body.h>

#include "ConfigurationModel.h"
#include "MainWindow.h"

ConfigurationModel::ConfigurationModel(QObject* parent) :
	QAbstractTableModel(parent)
{
}

ConfigurationModel::~ConfigurationModel()
{
}

int
ConfigurationModel::columnCount(const QModelIndex& parent) const
{
	return 1;
}

Qt::ItemFlags
ConfigurationModel::flags(const QModelIndex &index) const
{
	if (!index.isValid())
	{
		return Qt::NoItemFlags;
	}
	
	return QAbstractItemModel::flags(index) | Qt::ItemIsEditable;
}

QVariant
ConfigurationModel::headerData(int section, Qt::Orientation orientation, int role) const
{
	if (nullptr == MainWindow::instance()->dynamicModel)
	{
		return QVariant();
	}
	
	if (Qt::DisplayRole == role && Qt::Vertical == orientation)
	{
		if (rl::mdl::Kinematic* kinematic = dynamic_cast<rl::mdl::Kinematic*>(MainWindow::instance()->dynamicModel.get()))
		{
			for (std::size_t i = 0, j = 0; i < kinematic->getJoints(); ++i)
			{
				rl::mdl::Joint* joint = kinematic->getJoint(i);
				
				for (std::size_t k = 0; k < joint->getDofPosition(); ++j, ++k)
				{
					if (section == j)
					{
						return QString::fromStdString(joint->getName());
					}
				}
			}
		}
	}
	
	return QVariant();
}

void
ConfigurationModel::operationalChanged(const QModelIndex& topLeft, const QModelIndex& bottomRight)
{
	this->beginResetModel();
	this->endResetModel();
}

bool
ConfigurationModel::setData(const QModelIndex& index, const QVariant& value, int role)
{
	if (nullptr == MainWindow::instance()->dynamicModel)
	{
		return false;
	}
	
	if (index.isValid() && Qt::EditRole == role)
	{
		if (rl::mdl::Kinematic* kinematic = dynamic_cast<rl::mdl::Kinematic*>(MainWindow::instance()->dynamicModel.get()))
		{
			if (dynamic_cast<PositionModel*>(this))
			{
				rl::math::Vector q = kinematic->getPosition();
				Eigen::Matrix<rl::math::Units, Eigen::Dynamic, 1> qUnits = kinematic->getPositionUnits();
				
				if (rl::math::Units::radian == qUnits(index.row()))
				{
					q(index.row()) = value.value<rl::math::Real>() * rl::math::constants::deg2rad;
				}
				else
				{
					q(index.row()) = value.value<rl::math::Real>();
				}
				
				kinematic->setPosition(q);
				kinematic->forwardPosition();
				
				for (std::size_t i = 0; i < MainWindow::instance()->geometryModels->getNumBodies(); ++i)
				{
					MainWindow::instance()->geometryModels->getBody(i)->setFrame(kinematic->getBodyFrame(i));
				}
			}
			else if (dynamic_cast<VelocityModel*>(this))
			{
				rl::math::Vector qd = kinematic->getVelocity();
				Eigen::Matrix<rl::math::Units, Eigen::Dynamic, 1> qdUnits = kinematic->getVelocityUnits();
				
				if (rl::math::Units::radian == qdUnits(index.row()))
				{
					qd(index.row()) = value.value<rl::math::Real>() * rl::math::constants::deg2rad;
				}
				else
				{
					qd(index.row()) = value.value<rl::math::Real>();
				}
				
				kinematic->setVelocity(qd);
			}
			else if (dynamic_cast<AccelerationModel*>(this))
			{
				rl::math::Vector qdd = kinematic->getAcceleration();
				Eigen::Matrix<rl::math::Units, Eigen::Dynamic, 1> qddUnits = kinematic->getAccelerationUnits();
				
				if (rl::math::Units::radian == qddUnits(index.row()))
				{
					qdd(index.row()) = value.value<rl::math::Real>() * rl::math::constants::deg2rad;
				}
				else
				{
					qdd(index.row()) = value.value<rl::math::Real>();
				}
				
				kinematic->setAcceleration(qdd);
			}
			else if (dynamic_cast<TorqueModel*>(this))
			{
				MainWindow::instance()->externalTorque(index.row()) = value.value<rl::math::Real>();
			}
			
			emit dataChanged(index, index);
			
			return true;
		}
	}
	
	return false;
}

bool
ConfigurationModel::setData(const rl::math::Vector& values)
{
	if (nullptr == MainWindow::instance()->dynamicModel)
	{
		return false;
	}
	
	if (rl::mdl::Kinematic* kinematic = dynamic_cast<rl::mdl::Kinematic*>(MainWindow::instance()->dynamicModel.get()))
	{
		if (dynamic_cast<PositionModel*>(this))
		{
			kinematic->setPosition(values);
			kinematic->forwardPosition();
			
			for (std::size_t i = 0; i < MainWindow::instance()->geometryModels->getNumBodies(); ++i)
			{
				MainWindow::instance()->geometryModels->getBody(i)->setFrame(kinematic->getBodyFrame(i));
			}
		}
		else if (dynamic_cast<VelocityModel*>(this))
		{
			kinematic->setVelocity(values);
		}
		else if (dynamic_cast<AccelerationModel*>(this))
		{
			kinematic->setAcceleration(values);
		}
		else if (dynamic_cast<TorqueModel*>(this))
		{
			MainWindow::instance()->externalTorque = values;
		}
		
		emit dataChanged(this->createIndex(0, 0), this->createIndex(this->rowCount(), this->columnCount()));
		
		return true;
	}
	
	return false;
}


int
PositionModel::rowCount(const QModelIndex& parent) const
{
	if (nullptr == MainWindow::instance()->dynamicModel)
	{
		return 0;
	}
	
	return MainWindow::instance()->dynamicModel->getDofPosition();
}


int
VelocityModel::rowCount(const QModelIndex& parent) const
{
	if (nullptr == MainWindow::instance()->dynamicModel)
	{
		return 0;
	}
	
	return MainWindow::instance()->dynamicModel->getDof();
}


int
AccelerationModel::rowCount(const QModelIndex& parent) const
{
	if (nullptr == MainWindow::instance()->dynamicModel)
	{
		return 0;
	}
	
	return MainWindow::instance()->dynamicModel->getDof();
}

int
TorqueModel::rowCount(const QModelIndex& parent) const
{
	if (nullptr == MainWindow::instance()->dynamicModel)
	{
		return 0;
	}
	
	return MainWindow::instance()->dynamicModel->getDof();
}

QVariant
PositionModel::data(const QModelIndex& index, int role) const
{
	if (nullptr == MainWindow::instance()->dynamicModel)
	{
		return QVariant();
	}
	
	if (!index.isValid())
	{
		return QVariant();
	}
	
	switch (role)
	{
	case Qt::DisplayRole:
	case Qt::EditRole:
		{
			rl::math::Vector values = MainWindow::instance()->dynamicModel->getPosition();
			Eigen::Matrix<rl::math::Units, Eigen::Dynamic, 1> units = MainWindow::instance()->dynamicModel->getPositionUnits();
						
			if (rl::math::Units::radian == units(index.row()))
			{
				return values(index.row()) * rl::math::constants::rad2deg;
			}
			else
			{
				return values(index.row());
			}
		}
		break;
	case Qt::TextAlignmentRole:
		return Qt::AlignRight;
		break;
	default:
		break;
	}
	
	return QVariant();
}

QVariant
VelocityModel::data(const QModelIndex& index, int role) const
{
	if (nullptr == MainWindow::instance()->dynamicModel)
	{
		return QVariant();
	}
	
	if (!index.isValid())
	{
		return QVariant();
	}
	
	switch (role)
	{
	case Qt::DisplayRole:
	case Qt::EditRole:
		{
			rl::math::Vector values = MainWindow::instance()->dynamicModel->getVelocity();
			Eigen::Matrix<rl::math::Units, Eigen::Dynamic, 1> units = MainWindow::instance()->dynamicModel->getVelocityUnits();
			
			if (rl::math::Units::radian == units(index.row()))
			{
				return values(index.row()) * rl::math::constants::rad2deg;
			}
			else
			{
				return values(index.row());
			}
		}
		break;
	case Qt::TextAlignmentRole:
		return Qt::AlignRight;
		break;
	default:
		break;
	}
	
	return QVariant();
}

QVariant
AccelerationModel::data(const QModelIndex& index, int role) const
{
	if (nullptr == MainWindow::instance()->dynamicModel)
	{
		return QVariant();
	}
	
	if (!index.isValid())
	{
		return QVariant();
	}
	
	switch (role)
	{
	case Qt::DisplayRole:
	case Qt::EditRole:
		{
			rl::math::Vector values = MainWindow::instance()->dynamicModel->getAcceleration();
			Eigen::Matrix<rl::math::Units, Eigen::Dynamic, 1> units = MainWindow::instance()->dynamicModel->getAccelerationUnits();
			
			if (rl::math::Units::radian == units(index.row()))
			{
				return values(index.row()) * rl::math::constants::rad2deg;
			}
			else
			{
				return values(index.row());
			}
		}
		break;
	case Qt::TextAlignmentRole:
		return Qt::AlignRight;
		break;
	default:
		break;
	}
	
	return QVariant();
}


QVariant
TorqueModel::data(const QModelIndex& index, int role) const
{
	if (nullptr == MainWindow::instance()->dynamicModel)
	{
		return QVariant();
	}
	
	if (!index.isValid())
	{
		return QVariant();
	}
	
	switch (role)
	{
	case Qt::DisplayRole:
	case Qt::EditRole:
		return MainWindow::instance()->externalTorque(index.row());
		break;
	case Qt::TextAlignmentRole:
		return Qt::AlignRight;
		break;
	default:
		break;
	}
	
	return QVariant();
}
