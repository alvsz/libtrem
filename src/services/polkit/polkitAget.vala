/*
 * Copyright (C) 20011 Red Hat, Inc.
 *
 * Author: David Zeuthen <davidz@redhat.com>
 */

[CCode (cheader_filename = "polkitagent/polkitagent.h")]
namespace libTrem {
  private class AuthRequest {
    public unowned PolkitAuthenticationAgent agent;
    public Cancellable? cancellable;
    public ulong handler_id;

    public string action_id;
    public string message;
    public string icon_name;
    public Polkit.Details details;
    public string cookie;
    public List<weak Polkit.Identity> identities;

    public Task simple;

    public AuthRequest(PolkitAuthenticationAgent agent, string action_id, string message,
        string icon_name, Polkit.Details details, string cookie, List<Polkit.Identity> identities,
        Cancellable? cancellable) {
      this.agent = agent;
      this.action_id = action_id;
      this.message = message;
      this.icon_name = icon_name;
      this.details = details;
      this.cookie = cookie;
      this.identities = identities.copy ();
      this.cancellable = cancellable;

      this.simple = new Task (agent, cancellable, null);
      simple.set_name (cookie);

      identities.foreach ((i) => {
        i.ref ();
      });
    }

    ~AuthRequest () {
      identities.foreach ((i) => {
        i.unref ();
      });
    }
  }

  public class PolkitAuthenticationAgent : PolkitAgent.Listener {
    private List<AuthRequest> scheduled_requests = new List<AuthRequest> ();
    private AuthRequest? current_request = null;
    private pointer handle = null;

    public signal void initiate (string action_id, string message, string icon_name, string cookie, List<string> user_names);
    public signal void cancel ();
    
    public PolkitAuthenticationAgent () {
      Object();
    }

    ~PolkitAuthenticationAgent () {
      unregister ();
    }

    public async override bool initiate_authentication (string action_id, string message, string icon_name, Polkit.Details details, string cookie, GLib.List<Polkit.Identity> identities, GLib.Cancellable? cancellable) throws Error {
      var request = new AuthRequest (this, action_id, message, icon_name, details, cookie, identities, cancellable);

      if (cancellable != null) {
        request.handler_id = cancellable.connect (() => {
            var id = Idle.add (() => {
              if (request == request.agent.current_request)            
                request.agent.cancel ();
              else
                request.agent.auth_request_complete (request, false);

              return false;
              });
              Source.set_name_by_id (id, "[gnome-shell] handle_cancelled_in_idle");
          });
      }

      scheduled_requests.append (request);
      maybe_process_next_request ();

      return yield wait_for_request (request.simple);
    }

    private async bool wait_for_request (Task t) throws Error {
      var loop = new MainLoop ();
      t.notify.connect (() => {
          loop.quit ();
          });
      loop.run ();

      return t.propagate_boolean ();
    }

    public new void register () throws Error {
      var subject = new Polkit.UnixSession.for_process_sync (Posix.getpid (), null);
      if (subject == null)
        throw new Polkit.Error.FAILED ("PolKit failed to properly get our session");

      this.handle = base.register (PolkitAgent.RegisterFlags.NONE, subject, null);
    }

    public new void unregister () {
      if (scheduled_requests != null) {
        scheduled_requests.foreach ((r) => {
          auth_request_complete (r, true);
        });

        if (current_request != null)
          auth_request_complete (current_request, true);

        if (handle != null) {
          PolkitAgent.Listener.unregister ((void*)handle);
        }
      }
    }


    public void complete (bool dismissed) {
      return_if_fail (current_request != null);
      auth_request_complete (current_request, dismissed);
    }

    private void auth_request_complete (AuthRequest request, bool dismissed) {
      var is_current = current_request == request;

      // printerr ("COMPLETING %s %s cookie %s\n", is_current ? "CURRENT" : "SCHEDULED", request.action_id, request.cookie);

      if (!is_current)
        scheduled_requests.remove (request);

      request.cancellable.disconnect (request.handler_id);

      if (dismissed)
        request.simple.return_error (new Polkit.Error.CANCELLED ("Authentication dialog was dismissed by the user"));
      else
        request.simple.return_boolean (true);
      
      if (is_current) {
        current_request = null;
        maybe_process_next_request ();
      }
    }

    private void maybe_process_next_request () {
      // printerr ("MAYBE_PROCESS cur=%p len(scheduled)=%u\n", current_request, scheduled_requests.length ());
      
      if (current_request == null && scheduled_requests != null) {
        var request = scheduled_requests.data;
        current_request = request;
        scheduled_requests.remove (request);

        // printerr ("INITIATING %sauth_request_initiate cookie %s\n", request.action_id, request.cookie);
        auth_request_initiate (request);
      }
    }

    private void auth_request_initiate (AuthRequest request) {
      var user_names = new List<string> ();

      foreach (var identity in request.identities) {
        var unix_user = identity as Polkit.UnixUser;

        if (unix_user != null) {
          unowned Posix.Passwd? pwd = Posix.getpwuid (unix_user.get_uid ());

          if (pwd != null) {
            if (pwd.pw_name.validate ())
              user_names.append (pwd.pw_name);
            else
              warning ("Invalid UTF-8 in username for uid %d. Skipping", unix_user.get_uid ());
            
          } else
            warning ("Error looking up user name for uid %d", unix_user.get_uid());
        } else {
          warning ("Unsupporting identity of GType %s", identity.get_type().name());
        }
      }

      initiate (request.action_id, request.message, request.icon_name, request.cookie, user_names);
    }
  }
}
