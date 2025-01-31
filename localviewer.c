#include <gtk/gtk.h>
#include <webkit2/webkit2.h>
#include <gio/gio.h>
#include <string.h>

static char url[1024];
// Callback function to update the window title
static void title_changed_callback(WebKitWebView *webview, GParamSpec *pspec, gpointer user_data) {
    GtkWindow *window = GTK_WINDOW(user_data);
    const gchar *title = webkit_web_view_get_title(webview);

    if (title) {
        gtk_window_set_title(window, title);
    }
}

// Activate function to create the WebView window
static void activate(GtkApplication *app, gpointer user_data) {
    GtkWidget *window;
    GtkWidget *webview;

    // Create the main application window
    window = gtk_application_window_new(app);
    gtk_window_set_title(GTK_WINDOW(window), "Loading...");
    gtk_window_set_default_size(GTK_WINDOW(window), 1280, 768);

    // Create a WebKit WebView widget
    webview = webkit_web_view_new();

    // Disable scrollbars via settings
    WebKitSettings *settings = webkit_web_view_get_settings(WEBKIT_WEB_VIEW(webview));
    g_object_set(settings, "enable-overlay-scrollbars", FALSE, NULL);
    g_object_set(settings, "enable-default-context-menu", FALSE, NULL);

    // Hide scrollbars using CSS
    WebKitUserContentManager *content_manager = webkit_web_view_get_user_content_manager(WEBKIT_WEB_VIEW(webview));
    webkit_user_content_manager_add_style_sheet(
        content_manager,
        webkit_user_style_sheet_new(
            "::-webkit-scrollbar { display: none; }",
            WEBKIT_USER_CONTENT_INJECT_ALL_FRAMES,
            WEBKIT_USER_STYLE_LEVEL_USER,
            NULL,
            NULL
        )
    );

    webkit_web_view_load_uri(WEBKIT_WEB_VIEW(webview), url);

    // Connect the title change signal
    g_signal_connect(webview, "notify::title", G_CALLBACK(title_changed_callback), window);

    // Add the WebView to the window
    gtk_container_add(GTK_CONTAINER(window), webview);

    // Show all widgets
    gtk_widget_show_all(window);
}

// Handle command-line arguments properly
static int command_line_handler(GApplication *app, GApplicationCommandLine *cmdline, gpointer user_data) {
    gchar **args;
    int argc;
    
    args = g_application_command_line_get_arguments(cmdline, &argc);

    if (argc > 1) {
        if (g_str_has_prefix(args[1], "file://")) {
            strncpy(url, args[1], sizeof(url) - 1);
        } else {
            snprintf(url, sizeof(url), "file://%s", args[1]);
        }
        url[sizeof(url) - 1] = '\0'; // Ensure null termination
    }

    g_application_activate(app); // Activate the application manually
    g_strfreev(args);
    return 0;
}

int main(int argc, char **argv) {
    GtkApplication *app;
    int status;

    // Create a new GTK application with the correct application ID
    app = gtk_application_new("com.the-abra.WebView", G_APPLICATION_HANDLES_COMMAND_LINE);

    // Connect signals
    g_signal_connect(app, "activate", G_CALLBACK(activate), NULL);
    g_signal_connect(app, "command-line", G_CALLBACK(command_line_handler), NULL);

    // Run the application
    status = g_application_run(G_APPLICATION(app), argc, argv);

    // Cleanup
    g_object_unref(app);
    return status;
}
