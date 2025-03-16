[CCode (cheader_filename = "libnm/NetworkManager.h,libnm/nm-secret-agent-old.h")]
namespace NetworkAgent {
    public class AgentRequest : Object {

    }

    public class NetworkAgent : NM.SecretAgentOld {
        private HashTable<string, AgentRequest> requests = new HashTable<string, AgentRequest>(GLib.str_hash,GLib.str_equal);

        public void hello() {
            stdout.printf("Hello World, MyLib\n");

            requests.foreach((a,b) => {
                    print("%s %p\n", a,b);
            });
        }

        public int sum(int x, int y) {
            return x + y;
        }
    }
}
