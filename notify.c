#include <gtk/gtk.h>

// Callback function to close the window when the "Done" button is clicked
static void on_button_clicked(GtkWidget *button, gpointer window) {
    gtk_widget_destroy(GTK_WIDGET(window));
}

// Main function to set up the window and message box
int main(int argc, char *argv[]) {
    // Initialize GTK
    if (!gtk_init_check(&argc, &argv)) {
        g_print("GTK initialization failed.\n");
        return 1;
    }

    // Check if title and message arguments are provided
    if (argc < 3) {
        g_print("Usage: %s \"Window Title\" \"Message\"\n", argv[0]);
        return 1;
    }

    // Get title and message from arguments
    const char *window_title = argv[1];
    const char *message = argv[2];

    // Create a new top-level window
    GtkWidget *window = gtk_window_new(GTK_WINDOW_TOPLEVEL);
    gtk_window_set_title(GTK_WINDOW(window), window_title);
    gtk_window_set_default_size(GTK_WINDOW(window), 350, 200);
    gtk_window_set_resizable(GTK_WINDOW(window), FALSE);
    gtk_container_set_border_width(GTK_CONTAINER(window), 10);

    // Create a header bar with a dynamic title
    GtkWidget *header_bar = gtk_header_bar_new();
    gtk_header_bar_set_title(GTK_HEADER_BAR(header_bar), window_title);
    gtk_header_bar_set_show_close_button(GTK_HEADER_BAR(header_bar), TRUE);
    gtk_window_set_titlebar(GTK_WINDOW(window), header_bar);

    // Create a vertical box layout (main container)
    GtkWidget *vbox = gtk_box_new(GTK_ORIENTATION_VERTICAL, 10);
    gtk_container_add(GTK_CONTAINER(window), vbox);

    // Create a label with a smaller, normal-weight font
    GtkWidget *label = gtk_label_new(NULL);
    gchar *markup = g_strdup_printf("<span font='12'>%s</span>", message); // Font size reduced to 12, no bold
    gtk_label_set_markup(GTK_LABEL(label), markup);
    g_free(markup);

    // Ensure text wraps within a smaller width
    gtk_label_set_max_width_chars(GTK_LABEL(label), 40);
    gtk_label_set_line_wrap(GTK_LABEL(label), TRUE);
    gtk_label_set_justify(GTK_LABEL(label), GTK_JUSTIFY_CENTER);
    gtk_widget_set_halign(label, GTK_ALIGN_CENTER);
    gtk_box_pack_start(GTK_BOX(vbox), label, TRUE, TRUE, 5);

    // Create an empty expanding box to push the button to the bottom
    GtkWidget *spacer = gtk_box_new(GTK_ORIENTATION_VERTICAL, 0);
    gtk_box_pack_start(GTK_BOX(vbox), spacer, TRUE, TRUE, 5);

    // Create a horizontal box for bottom-right alignment
    GtkWidget *hbox = gtk_box_new(GTK_ORIENTATION_HORIZONTAL, 0);
    gtk_box_pack_start(GTK_BOX(vbox), hbox, FALSE, FALSE, 0);

    // Create the "Done" button and position it at the bottom-right
    GtkWidget *button = gtk_button_new_with_label("Done");
    gtk_widget_set_size_request(button, 60, 30);  // Shorter button
    gtk_widget_set_halign(button, GTK_ALIGN_END); // Align right
    gtk_widget_set_margin_top(button, 10);
    gtk_widget_set_margin_bottom(button, 10);
    gtk_box_pack_end(GTK_BOX(hbox), button, FALSE, FALSE, 10); // Push button to the right

    // Set a tooltip for better UX
    gtk_widget_set_tooltip_text(button, "Click to close the window");

    // Connect the "Done" button to the callback function
    g_signal_connect(button, "clicked", G_CALLBACK(on_button_clicked), window);

    // Connect the window to the GTK main quit function
    g_signal_connect(window, "destroy", G_CALLBACK(gtk_main_quit), NULL);

    // Show all elements in the window
    gtk_widget_show_all(window);

    // Run the GTK main loop
    gtk_main();

    return 0;
}
