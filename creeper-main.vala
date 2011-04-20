using Wnck;
using Gee;
using Gtk;

class Creeper.MainWindow {

	private Gtk.Builder builder;
	private Gtk.Window window;
	private Gtk.Toolbar toolbar;
	private Wnck.Screen screen;
	private Creeper.ActivitiesView view;

	private Timer timer_today;

	private Activity current_activity;
	private Gee.ArrayList<Activity> activities;

	public MainWindow () {
		activities = new Gee.ArrayList<Activity> ();

		builder = new Gtk.Builder ();
		try {
			builder.add_from_file ("main.ui");
		} catch (Error e) {
			error ("Unable to load UI file: " + e.message);
		}
		window = builder.get_object ("window1") as Gtk.Window;
		toolbar = builder.get_object ("toolbar1") as Gtk.Toolbar;
		var table = builder.get_object ("table2") as Gtk.Table;

		toolbar.get_style_context ().add_class (Gtk.STYLE_CLASS_PRIMARY_TOOLBAR);
		view = new ActivitiesView (table);
		window.destroy.connect (Gtk.main_quit);

		timer_today = new Timer ();

		screen = Wnck.Screen.get_default ();
		screen.active_window_changed.connect ( (screen, previous) =>
			{
				// stop previous activity
				if (current_activity != null) {
					current_activity.pause ();
					debug (@"Pausing previous activity, ran for $(current_activity.time)");

				}
				// get current application
				var win = screen.get_active_window ();
				if (win == null) return;

				var app = win.get_application ();

				// do I have to do this stupid scholar code?
				bool found = false; int i = 0;
				while (i < activities.size && !found) {
					var a = activities.get (i);
					if (a.name == app.get_name ()) {
						current_activity = a;
						found = true;
					}
					i++;
				}

				if (i >= activities.size) {
					current_activity = new Activity.from_app (app);
					add_activity (current_activity);
					debug (@"Created new activity: $current_activity");
				} else {
					current_activity = activities.get (i);
				}

				debug (@"Switched to: $current_activity");
				current_activity.start ();
				update_view ();
			});
	}

	public bool add_activity (Activity a) {
		activities.add (a);
		activities.sort ((CompareFunc)(compare_activities));
		return true;
	}

	public static int compare_activities (Activity a, Activity b) {
		if (a.timer.elapsed () > b.timer.elapsed ()) {
			return -1;
		} else if (a.timer.elapsed () < b.timer.elapsed ()) {
			return 1;
		} else { 
			return 0;
		}
	}

	public void update_view () {
		if (activities.size > 0) view.resize (activities.size, 3);
		// would be nicer to just add and re-order activites
		view.remove_all ();

		debug ("Total running time : %3.3f".printf (timer_today.elapsed ()));
		for (int i = 0; i < activities.size; i++) {
			var perc = activities.get(i).timer.elapsed () / timer_today.elapsed ();
			var str = "%3.2f".printf (perc);
			debug (@"Activity $(activities.get(i)) has been running " + str + "% of the time");
			view.render_row (activities.get(i), i, perc);
		}
		view.refresh ();
	}

	public void run () {
		window.show_all ();
		Gtk.main ();
	}

	public static int main(string []args) {
		var app = new Gtk.Application ("org.gnome.creeper", 0);
		app.activate.connect ( () => {
				weak GLib.List list = app.get_windows ();
				if (list == null) {
					var mainwindow = new MainWindow ();
					mainwindow.run ();
				} else {
					debug ("already running!");
				}
			});
		return app.run (args);
	}
}		

