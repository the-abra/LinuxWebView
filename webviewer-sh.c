#include <gtk/gtk.h>
#include <webkit2/webkit2.h>
#include <gio/gio.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>

static char url[1024];

// Function to execute a shell command securely and return the output
static gchar* run_shell_command(const gchar *command) {

    g_autoptr(GError) error = NULL;
    g_autofree gchar *stdout_output = NULL;
    
    // Whitelist commands (only allow "ls" and "whoami")
    /*if (g_strcmp0(command, "ls") != 0 && g_strcmp0(command, "whoami") != 0) {
        return g_strdup("Error: Command not allowed.");
    }*/

    // Open a process to run the command and capture output
    g_autoptr(GSubprocess) subprocess = g_subprocess_new(
        G_SUBPROCESS_FLAGS_STDOUT_PIPE | G_SUBPROCESS_FLAGS_STDERR_PIPE, 
        &error, "/bin/sh", "-c", command, NULL
    );

    if (!subprocess) {
        return g_strdup(error->message);  // Return error message
    }

    // Read output from the subprocess
    if (!g_subprocess_communicate_utf8(subprocess, NULL, NULL, &stdout_output, NULL, &error)) {
        return g_strdup(error->message);
    }

    return g_strdup(stdout_output); // Return captured output
}

// Callback to handle JavaScript execution completion
static void on_js_execution_done(GObject *object, GAsyncResult *result, gpointer user_data) {
    WebKitWebView *webview = WEBKIT_WEB_VIEW(object);
    GError *error = NULL;
    
    webkit_web_view_run_javascript_finish(webview, result, &error);
    if (error) {
        g_print("JavaScript execution failed: %s\n", error->message);
        g_error_free(error);
    } else {
        g_print("JavaScript executed successfully.\n");
    }
}

// Callback to handle messages from JavaScript
static void on_js_message_received(WebKitUserContentManager *manager, WebKitJavascriptResult *result, gpointer webview) {
    JSCValue *value = webkit_javascript_result_get_js_value(result);
    gchar *command = jsc_value_to_string(value);
    
    if (command) {
        g_print("Received shell command: %s\n", command);
        gchar *output = run_shell_command(command);
        g_print("Command Output: %s\n", output);

        // Escape output for safe JavaScript execution
        gchar *escaped_output = g_strescape(output, NULL);
        gchar *js_code = g_strdup_printf("window.onShellResult && window.onShellResult(\"%s\");", escaped_output);
        
        // Run JavaScript and check for errors
        webkit_web_view_run_javascript(WEBKIT_WEB_VIEW(webview), js_code, NULL, (GAsyncReadyCallback)on_js_execution_done, NULL);

        g_free(command);
        g_free(output);
        g_free(escaped_output);
        g_free(js_code);
    }
}

// Inject JavaScript function for communication
static void inject_js(WebKitWebView *webview) {
    WebKitUserContentManager *content_manager = webkit_web_view_get_user_content_manager(webview);

    // Register message handler
    webkit_user_content_manager_register_script_message_handler(content_manager, "shellHandler");

    // Connect the message handler to receive messages
    g_signal_connect(content_manager, "script-message-received::shellHandler", G_CALLBACK(on_js_message_received), webview);

    // Inject JavaScript function into the page
    const gchar *script = "window.shell = function(command) {"
                          "    window.webkit.messageHandlers['shellHandler'].postMessage(command);"
                          "};"
                          "window.onShellResult = window.onShellResult || function(output) {"
                          "    console.log('Shell Output:', output);"
                          "};";

    WebKitUserScript *user_script = webkit_user_script_new(
        script,
        WEBKIT_USER_CONTENT_INJECT_ALL_FRAMES,
        WEBKIT_USER_SCRIPT_INJECT_AT_DOCUMENT_START,
        NULL,
        NULL
    );

    webkit_user_content_manager_add_script(content_manager, user_script);
}

// Callback function to update the window title dynamically
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

    // Inject JavaScript for shell execution
    inject_js(WEBKIT_WEB_VIEW(webview));

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

    // Load the provided URL or default to a blank page
    webkit_web_view_load_uri(WEBKIT_WEB_VIEW(webview), url[0] ? url : "about:blank");

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
        if (g_str_has_prefix(args[1], "file://") || g_str_has_prefix(args[1], "http://") || g_str_has_prefix(args[1], "https://")) {
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

    // Create a new GTK application with command-line handling
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
