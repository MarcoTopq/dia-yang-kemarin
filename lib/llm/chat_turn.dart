/// Satu giliran percakapan yang dikirim ke provider.
/// Sengaja provider-agnostic; tiap provider memetakan ke formatnya sendiri.
enum ChatRole { user, model }

class ChatTurn {
  const ChatTurn(this.role, this.text);

  const ChatTurn.user(this.text) : role = ChatRole.user;
  const ChatTurn.model(this.text) : role = ChatRole.model;

  final ChatRole role;
  final String text;
}
