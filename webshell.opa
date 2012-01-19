// license: AGPL
// (c) MLstate, 2011, 2012
// author: Henri Binsztok
// author: Adam Koprowski (adding Facebook-connectivity)

import stdlib.themes.bootstrap
import stdlib.widgets.bootstrap

type User.t = {guest} or {FbLogin.user fb_user}

WB = WBootstrap

function focus(set) {
	Log.warning("focus", set);
	#status = "Focus: {set}";
}

function prompt() {
  user_name =
    match (Login.get_current_user()) {
      case {guest}: "anonymous"
      case {~fb_user}: FbLogin.get_name(fb_user)
    }
  <span class="prompt">
    {"web: {user_name} $ "}
  </span>
}

function warner(msg) {
	#terminal =+ msg;
}

function asker(f, msg) {
	#terminal =+ msg;
}

function loop(_) {
	LineEditor.init(#editor, readevalwrite(_), true);
}

function answer(expr) {
	match (Parser.try_parse(Calc.shell, expr)) {
		case { none }: "syntax error"
		case { some: { value: result } }: "{result}"
		case { some: { ~command, ~arg } }: "{command}({arg})"
	}
}
		
client function readevalwrite(expr) {
	element = 
		<div>
			<span>{prompt()}</span>
			<span>{expr}</span>
		</div>
		<div>{answer(expr)}</div>;
	#terminal =+ element;
	LineEditor.clear();
	Dom.scroll_to_bottom(Dom.select_window());
}

function page() {
  topbar =
    WB.Navigation.topbar(
      WB.Layout.fixed(
        WB.Navigation.brand(<>webshell</>, none, ignore) <+>
        <h3 style="float: right">
          <a>You can sign in with:</>
          {FbLogin.xhtml}
        </>
      )
    )
  html = WB.Layout.fixed(
    WB.Typography.header(1, none,
      <div id="terminal"/>
        <div id="line" onready={loop}>
          {prompt()}
          <span id="editor"/>
        </div>
     )
   ) |> Xhtml.update_class("body", _)
  Resource.html("webshell",
     <>
       {topbar}
       {html}
       <div id="status"/>
     </>
   )
}

dispatcher = parser
| "/connect?" data=(.*) ->
    {
      FbLogin.login(Text.to_string(data)) |> Login.set_current_user
      Resource.default_redirection_page("/")
    }
| .* ->
    page()

Server.start(Server.http, { custom: dispatcher })

css = css
  .body { padding-top: 50px }