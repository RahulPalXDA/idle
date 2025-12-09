/*
 * Idle Master (X11 Userspace Edition)
 * Logic: Monitors X11 Idle time. Moves mouse with XTest.
 * Network: Uses libcurl for Telegram.
 * Permissions: Runs as USER (No Sudo).
 * Dependencies: libX11, libXss, libXtst, libcurl
 */

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <time.h>
#include <signal.h>
#include <X11/Xlib.h>
#include <X11/extensions/XTest.h>
#include <X11/extensions/scrnsaver.h>
#include <curl/curl.h>

// --- CONFIGURATION ---
// REPLACE THESE WITH YOUR REAL ID
#define TG_BOT_TOKEN ""
#define TG_CHAT_ID ""

#define IDLE_THRESHOLD_MS 30000  // 30 seconds
#define JIGGLE_INTERVAL_MS 1000  // 1 second
#define JIGGLE_PIXELS 10         // 10 pixels (safer for all systems)

volatile sig_atomic_t keep_running = 1;

void handle_signal(int sig) {
    keep_running = 0;
}

// --- NETWORK: LIBCURL ---
size_t write_callback(void *contents, size_t size, size_t nmemb, void *userp) {
    return size * nmemb; // Ignore response
}

void send_telegram(const char *msg) {
    CURL *curl = curl_easy_init();
    if(curl) {
        char url[512];
        char post_data[512];
        
        snprintf(url, sizeof(url), "https://api.telegram.org/bot%s/sendMessage", TG_BOT_TOKEN);
        snprintf(post_data, sizeof(post_data), "chat_id=%s&text=%s", TG_CHAT_ID, msg);

        curl_easy_setopt(curl, CURLOPT_URL, url);
        curl_easy_setopt(curl, CURLOPT_POSTFIELDS, post_data);
        curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, write_callback); 
        
        curl_easy_perform(curl);
        curl_easy_cleanup(curl);
    }
}

// --- X11 HELPERS ---
unsigned long get_idle_time(Display *dpy) {
    XScreenSaverInfo *info = XScreenSaverAllocInfo();
    if (!info) return 0;
    
    XScreenSaverQueryInfo(dpy, DefaultRootWindow(dpy), info);
    unsigned long idle = info->idle;
    
    XFree(info);
    return idle;
}

void jiggle_mouse(Display *dpy) {
    // Move 1 pixel right, then 1 pixel left immediately
    // This counts as activity but the cursor visually stays put
    XTestFakeRelativeMotionEvent(dpy, JIGGLE_PIXELS, 0, CurrentTime);
    XTestFakeRelativeMotionEvent(dpy, -JIGGLE_PIXELS, 0, CurrentTime);
    XFlush(dpy);
}

// --- MAIN ---
int main() {
    signal(SIGINT, handle_signal);
    signal(SIGTERM, handle_signal);

    // 1. Connect to X Server
    Display *dpy = XOpenDisplay(NULL);
    if (!dpy) {
        return 1;
    }

    // 2. SAFETY CHECK: Verify XScreenSaver extension exists
    int event_base, error_base;
    if (!XScreenSaverQueryExtension(dpy, &event_base, &error_base)) {
        XCloseDisplay(dpy);
        return 1;
    }

    curl_global_init(CURL_GLOBAL_ALL);
    srand(time(NULL));



    while (keep_running) {
        unsigned long current_idle = get_idle_time(dpy);

        if (current_idle >= IDLE_THRESHOLD_MS) {
            // --- IDLE STATE ---
            send_telegram("User_is_Idle");
            time_t idle_start = time(NULL);

            while (keep_running) {
                jiggle_mouse(dpy);
                
                // Sleep 1 second
                struct timespec ts = {1, 0};
                nanosleep(&ts, NULL);

                // FIXED: Detect REAL human activity vs our own jiggle
                // After jiggling + sleeping 1000ms:
                // - If idle >= 900ms: No real user activity, our jiggle was the only event
                // - If idle < 900ms: A REAL human moved/typed during our 1s sleep!
                unsigned long current_idle = get_idle_time(dpy);
                if (current_idle < 900) {
                    time_t idle_end = time(NULL);
                    long long total_idle_seconds = (long long)(idle_end - idle_start);
                    long long hours = total_idle_seconds / 3600;
                    long long mins = (total_idle_seconds % 3600) / 60;
                    long long secs = total_idle_seconds % 60;
                    
                    char msg[128];
                    snprintf(msg, sizeof(msg), "User_Returned_(idle_%lldh_%lldm_%llds)", hours, mins, secs);
                    send_telegram(msg);
                    break; 
                }
            }
        } else {
            // --- WAIT STATE ---
            long time_left = IDLE_THRESHOLD_MS - current_idle;
            if (time_left < 1000) time_left = 1000;
            
            struct timespec ts;
            ts.tv_sec = time_left / 1000;
            ts.tv_nsec = (time_left % 1000) * 1000000;
            nanosleep(&ts, NULL);
        }
    }

    if (dpy) XCloseDisplay(dpy);
    curl_global_cleanup();

    return 0;
}
