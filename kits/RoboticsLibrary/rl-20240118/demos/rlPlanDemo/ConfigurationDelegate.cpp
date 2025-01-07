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

#include <QDoubleSpinBox>
#include <QModelIndex>
#include <rl/math/Constants.h>

#include "ConfigurationDelegate.h"
#include "MainWindow.h"

ConfigurationDelegate::ConfigurationDelegate(QObject* parent) :
	QItemDelegate(parent)
{
}

ConfigurationDelegate::~ConfigurationDelegate()
{
}

QWidget*
ConfigurationDelegate::createEditor(QWidget* parent, const QStyleOptionViewItem& option, const QModelIndex& index) const
{
	QDoubleSpinBox* editor = new QDoubleSpinBox(parent);
	
	rl::math::Vector maximum = MainWindow::instance()->model->getMaximum();
	rl::math::Vector minimum = MainWindow::instance()->model->getMinimum();
	Eigen::Matrix<rl::math::Units, Eigen::Dynamic, 1> qUnits = MainWindow::instance()->model->getPositionUnits();
	Eigen::Matrix<bool, Eigen::Dynamic, 1> wraparounds = MainWindow::instance()->model->getWraparounds();
	
	if (rl::math::Units::radian == qUnits(index.row()))
	{
		editor->setDecimals(2);
		editor->setMinimum(minimum(index.row()) * rl::math::constants::rad2deg);
		editor->setMaximum(maximum(index.row()) * rl::math::constants::rad2deg);
		editor->setSingleStep(1.0);
	}
	else
	{
		editor->setDecimals(4);
		editor->setMinimum(minimum(index.row()));
		editor->setMaximum(maximum(index.row()));
		editor->setSingleStep(0.01);
	}
	
	editor->setWrapping(wraparounds(index.row()));
	
	QObject::connect(editor, SIGNAL(valueChanged(double)), this, SLOT(valueChanged(double)));
	
	return editor;
}

void
ConfigurationDelegate::setEditorData(QWidget* editor, const QModelIndex& index) const
{
	QDoubleSpinBox* doubleSpinBox = static_cast<QDoubleSpinBox*>(editor);
	doubleSpinBox->setValue(index.model()->data(index, Qt::EditRole).toDouble());
}

void
ConfigurationDelegate::setModelData(QWidget* editor, QAbstractItemModel* model, const QModelIndex& index) const
{
	QDoubleSpinBox* doubleSpinBox = static_cast<QDoubleSpinBox*>(editor);
	doubleSpinBox->interpretText();
	model->setData(index, doubleSpinBox->value(), Qt::EditRole);
}

void
ConfigurationDelegate::updateEditorGeometry(QWidget* editor, const QStyleOptionViewItem& option, const QModelIndex& index) const
{
	editor->setGeometry(option.rect);
}

void
ConfigurationDelegate::valueChanged(double d)
{
	emit commitData(static_cast<QWidget*>(QObject::sender()));
}
