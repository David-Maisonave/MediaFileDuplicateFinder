// /*
//     Copyright (C) 2021 0x90d
//     This file is part of VideoDuplicateFinder
//     VideoDuplicateFinder is free software: you can redistribute it and/or modify
//     it under the terms of the GPLv3 as published by
//     the Free Software Foundation, either version 3 of the License, or
//     (at your option) any later version.
//     VideoDuplicateFinder is distributed in the hope that it will be useful,
//     but WITHOUT ANY WARRANTY without even the implied warranty of
//     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//     GNU General Public License for more details.
//     You should have received a copy of the GNU General Public License
//     along with VideoDuplicateFinder.  If not, see <http://www.gnu.org/licenses/>.
// */
//

using System.Runtime.InteropServices;
using Avalonia;
using Avalonia.Controls;
using Avalonia.Controls.ApplicationLifetimes;
using Avalonia.Input;
using Avalonia.Markup.Xaml;
using Avalonia.Markup.Xaml.Styling;
using Avalonia.Media;
using Avalonia.Themes.Fluent;
using VDF.GUI.Data;
using VDF.GUI.Mvvm;
using System.Windows;
using Avalonia.Interactivity;
using Avalonia.Threading;
using Avalonia.Controls.Shapes;
using FFmpeg.AutoGen;
using System.Collections.Generic;
using System.Threading;
using VDF.Core;
namespace VDF.GUI.Views {
	public class MainWindow : Window {
		private bool keepBackupFile;
		private bool hasExited;
		// Logic to capture keyboard input within the first few seconds of program startup, so-as to allow
		// the UI to be reset in case the UI settings are corrupt or are incompatible with new monitors settings.
		private bool resetUI_Allowed = true;
		private DispatcherTimer? resetUI_Timer = null;
		private const int resetUI_QtySecondsFromStartup = 3;

		public readonly Core.FFTools.FFHardwareAccelerationMode InitialHwMode;
		public MainWindow() {
			//Settings must be load before XAML is parsed
			SettingsFile.LoadSettings();
			InitializeComponent();
			AddHandler(KeyDownEvent, OnKeyDown, RoutingStrategies.Tunnel | RoutingStrategies.Bubble);
			Closing += MainWindow_Closing;
			Opened += MainWindow_Opened;
			//Don't use this Window.OnClosing event,
			//datacontext might not be the same due to Avalonia internal handling data differently

			this.FindControl<ListBox>("ListboxIncludelist")!.AddHandler(DragDrop.DropEvent, DropInclude);
			this.FindControl<ListBox>("ListboxIncludelist")!.AddHandler(DragDrop.DragOverEvent, DragOver);
			this.FindControl<ListBox>("ListboxBlacklist")!.AddHandler(DragDrop.DropEvent, DropBlacklist);
			this.FindControl<ListBox>("ListboxBlacklist")!.AddHandler(DragDrop.DragOverEvent, DragOver);

			this.FindControl<ListBox>("ListboxIncludelist2")!.AddHandler(DragDrop.DropEvent, DropInclude);
			this.FindControl<ListBox>("ListboxIncludelist2")!.AddHandler(DragDrop.DragOverEvent, DragOver);
			this.FindControl<ListBox>("ListboxBlacklist2")!.AddHandler(DragDrop.DropEvent, DropBlacklist);
			this.FindControl<ListBox>("ListboxBlacklist2")!.AddHandler(DragDrop.DragOverEvent, DragOver);

			ApplicationHelpers.CurrentApplicationLifetime.Startup += MainWindow_Startup;
			ApplicationHelpers.CurrentApplicationLifetime.Exit += MainWindow_Exit;
			ApplicationHelpers.CurrentApplicationLifetime.ShutdownMode = ShutdownMode.OnExplicitShutdown;

			if (SettingsFile.Instance.UseMica &&
				RuntimeInformation.IsOSPlatform(OSPlatform.Windows) &&
				Environment.OSVersion.Version.Build >= 22000) {
				Background = null;
				TransparencyLevelHint = WindowTransparencyLevel.Mica;
				ExtendClientAreaChromeHints = Avalonia.Platform.ExtendClientAreaChromeHints.PreferSystemChrome;
				if (SettingsFile.Instance.DarkMode)
					this.FindControl<ExperimentalAcrylicBorder>("ExperimentalAcrylicBorderBackgroundBlack")!.IsVisible = true;
				else
					this.FindControl<ExperimentalAcrylicBorder>("ExperimentalAcrylicBorderBackgroundWhite")!.IsVisible = true;
			}

			if (!SettingsFile.Instance.DarkMode)
				((FluentTheme)Application.Current!.Styles[0]).Mode = FluentThemeMode.Light;

			if (RuntimeInformation.IsOSPlatform(OSPlatform.Linux)) {
				this.FindControl<TextBlock>("TextBlockWindowTitle")!.IsVisible = false;
			}
		}

		private void MainWindow_Opened(object? sender, EventArgs e) {
			if (RuntimeInformation.IsOSPlatform(OSPlatform.OSX)) {
				/*
				 * Due to Avalonia bug, window is bigger than screen size. 
				 * Status bar is hidden by MacOS launch bar,
				 * see https://github.com/0x90d/videoduplicatefinder/issues/391
				 */
				Height = 750d;
			}
			if (SettingsFile.Instance.AppWindowHeight != 0 && SettingsFile.Instance.AppWindowHeight > 0)
				Height = SettingsFile.Instance.AppWindowHeight;
			if (SettingsFile.Instance.AppWindowWidth != 0 && SettingsFile.Instance.AppWindowWidth > 0)
				Width = SettingsFile.Instance.AppWindowWidth;
			// The 2 below lines of code exist for testing purposes only. They're used to verify the UI reset logic works
			//SettingsFile.Instance.AppPositionX = 59000;  // Warning: Do NOT check in this line of code without commenting it out!!!!
			//SettingsFile.Instance.AppPositionY = 32000;  // Warning: Do NOT check in this line of code without commenting it out!!!!
			if (SettingsFile.Instance.AppPositionX != -1 && SettingsFile.Instance.AppPositionY != -1 &&
				SettingsFile.Instance.AppPositionX < this.MaxWidth && SettingsFile.Instance.AppPositionY < this.MaxHeight)
				Position = new PixelPoint(SettingsFile.Instance.AppPositionX, SettingsFile.Instance.AppPositionY);
			if (IsEffectivelyVisible == false) // It's possible that window is not visible if number of monitors change or if the monitor position changes since the last run
				Position = new PixelPoint(1, 1);
			resetUI_Timer = new DispatcherTimer(new TimeSpan(0,0, resetUI_QtySecondsFromStartup), DispatcherPriority.Input, StartUpResetUI_TimerHndlr);
			resetUI_Timer.Start();
		}

		void MainWindow_Closing(object? sender, System.ComponentModel.CancelEventArgs e) {
			e.Cancel = true;
			ConfirmClose();
		}

		async void ConfirmClose() {
			try {
				if (!keepBackupFile)
					File.Delete(ApplicationHelpers.MainWindowDataContext.BackupScanResultsFile);
			}
			catch { }
			SettingsFile.Instance.AppWindowHeight = (int)Height;
			SettingsFile.Instance.AppWindowWidth = (int)Width;
			SettingsFile.Instance.AppPositionX = Position.X;
			SettingsFile.Instance.AppPositionY = Position.Y;
			if (IsEffectivelyVisible == false || IsVisible == false || IsArrangeValid == false) {
				SettingsFile.Instance.AppWindowHeight = (int)0;
				SettingsFile.Instance.AppWindowWidth = (int)0;
				SettingsFile.Instance.AppPositionX = -1;
				SettingsFile.Instance.AppPositionY = -1;
			}
			if (keepBackupFile = await ApplicationHelpers.MainWindowDataContext.SaveScanResults()) {
				Closing -= MainWindow_Closing;
				ApplicationHelpers.CurrentApplicationLifetime.Shutdown();
			}
		}

		void MainWindow_Exit(object? sender, ControlledApplicationLifetimeExitEventArgs e) {
			if (hasExited) return;
			hasExited = true;
			SettingsFile.SaveSettings();
		}

		private void DragOver(object? sender, DragEventArgs e) {
			// Only allow Copy or Link as Drop Operations.
			e.DragEffects &= DragDropEffects.Copy | DragDropEffects.Link;

			// Only allow if the dragged data contains text or filenames.
			if (!e.Data.Contains(DataFormats.FileNames))
				e.DragEffects = DragDropEffects.None;
		}

		private void DropInclude(object? sender, DragEventArgs e) {
			if (!e.Data.Contains(DataFormats.FileNames)) return;

			foreach (string file in e.Data.GetFileNames()!) {
				if (!Directory.Exists(file)) continue;
				if (!SettingsFile.Instance.Includes.Contains(file))
					SettingsFile.Instance.Includes.Add(file);
			}
		}
		private void DropBlacklist(object? sender, DragEventArgs e) {
			if (!e.Data.Contains(DataFormats.FileNames)) return;

			foreach (string file in e.Data.GetFileNames()!) {
				if (!Directory.Exists(file)) continue;
				if (!SettingsFile.Instance.Blacklists.Contains(file))
					SettingsFile.Instance.Blacklists.Add(file);
			}
		}

		void Thumbnails_ValueChanged(object? sender, NumericUpDownValueChangedEventArgs e) {
			if (ApplicationHelpers.MainWindow != null && ApplicationHelpers.MainWindowDataContext != null)
				ApplicationHelpers.MainWindowDataContext.Thumbnails_ValueChanged(sender, e);
		}

		void MainWindow_Startup(object? sender, ControlledApplicationLifetimeStartupEventArgs e) => ApplicationHelpers.MainWindowDataContext.LoadDatabase();

		void InitializeComponent() => AvaloniaXamlLoader.Load(this);
		private void OnKeyDown(object? sender, KeyEventArgs e) {
			if (resetUI_Allowed && e.KeyModifiers == KeyModifiers.Shift) 
				Position = new PixelPoint(1, 1);
		}
		private void StartUpResetUI_TimerHndlr(object? sender, EventArgs e) {
			if (resetUI_Timer != null) {
				resetUI_Timer.Stop();
				resetUI_Allowed = false;
			}
		}
	}
}
