import { StreamLanguage } from "@codemirror/language";
import { lua } from "@codemirror/legacy-modes/mode/lua";
import type { ReactCodeMirrorProps } from "@uiw/react-codemirror";
import ReactCodeMirror, { EditorView } from "@uiw/react-codemirror";
import * as css from "./CodeEditor.css.ts";
import icons from "../../icons.ts";
import type {
  CompletionContext,
  CompletionResult,
} from "@codemirror/autocomplete";
import { vars } from "../../css/theme-contract.css.ts";

export default function CodeEditor(
  props: {
    completions: (context: CompletionContext) => CompletionResult | null;
    isSuccesful: boolean;
  } & ReactCodeMirrorProps,
) {
  const { completions, isSuccesful, ...rawEditorProps } = props;

  const editorProps: ReactCodeMirrorProps = {
    minHeight: "25rem",
    theme: "dark",
    ...rawEditorProps,
  };
  editorProps.extensions = editorProps.extensions ?? [];
  const luaLanguage = StreamLanguage.define(lua);
  editorProps.extensions.push(luaLanguage);
  editorProps.extensions.push(
    luaLanguage.data.of({
      autocomplete: completions,
    }),
  );
  editorProps.extensions.push(
    EditorView.theme({
      "& *": {
        "font-family": vars.fonts.families.monospace,
        "font-weight": vars.fonts.weights.normal,
      },
    }),
  );
  editorProps.className = `${editorProps.className} ${css.codeEditor}`;

  return (
    <div className={css.container}>
      <ReactCodeMirror basicSetup={{ autocompletion: true }} {...editorProps} />
      <icons.Success
        className={`${css.status} ${css.success} ${isSuccesful ? css.show : ""}`}
      />
      <icons.Error
        className={`${css.status} ${css.error} ${isSuccesful ? "" : css.show}`}
      />
    </div>
  );
}
