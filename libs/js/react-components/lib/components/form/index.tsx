import {
  useId,
  type InputHTMLAttributes,
  type ReactNode,
  type SelectHTMLAttributes,
} from "react";
import * as css from "./Form.css.ts";
import { IdContext } from "./context.ts";

const disablePasswordManagersProps = {
  "data-1p-ignore": true,
  "data-lpignore": true,
  "data-protonpass-ignore": true,
  autoComplete: "off",
};

type InputProps = {
  label?: ReactNode;
  rightAttachment?: ReactNode;
};

export function Field(
  props: InputProps & { children: ReactNode; id?: string },
) {
  const { label, rightAttachment, children, id } = props;
  const localId = useId();

  const idInUse = id ?? localId;

  return (
    <>
      {label === undefined ? (
        ""
      ) : (
        <label className={css.label} htmlFor={idInUse}>
          {label}
        </label>
      )}
      <IdContext value={idInUse}>
        <div className={css.inputWrapper}>
          {children}
          {rightAttachment === undefined ? (
            ""
          ) : (
            <div className={css.attachment}>{rightAttachment}</div>
          )}
        </div>
      </IdContext>
    </>
  );
}

function Input(props: InputHTMLAttributes<HTMLInputElement> & InputProps) {
  const id = useId();
  const { label, rightAttachment, ...restProps }: InputProps = props;

  return (
    <Field id={id} label={label} rightAttachment={rightAttachment}>
      <input className={css.input} id={id} {...restProps} />
    </Field>
  );
}

export function Select(
  props: SelectHTMLAttributes<HTMLSelectElement> &
    InputProps & { children: ReactNode },
) {
  const id = useId();
  const { label, rightAttachment }: InputProps = props;
  const { children } = props;

  return (
    <Field id={id} label={label} rightAttachment={rightAttachment}>
      <select className={css.input} id={id} {...props}>
        {children}
      </select>
    </Field>
  );
}

export function NumberInput(
  props: InputHTMLAttributes<HTMLInputElement> & InputProps,
) {
  const id = useId();

  return (
    <>
      <Input type="number" id={id} {...props} />
    </>
  );
}

export function TextInput(
  props: InputHTMLAttributes<HTMLInputElement> &
    InputProps & {
      disablePasswordManagers?: boolean;
    },
) {
  const { disablePasswordManagers = true } = props;

  return (
    <>
      <Input
        type="text"
        {...props}
        {...(disablePasswordManagers === true
          ? disablePasswordManagersProps
          : {})}
      />
    </>
  );
}

export function Row({ children }: { children: ReactNode | ReactNode[] }) {
  return <div className={css.row}>{children}</div>;
}

export function Form({
  children,
  action,
}: {
  children: ReactNode | ReactNode[];
  action?: string | ((formData: FormData) => void | Promise<void>);
}) {
  return <form action={action}>{children}</form>;
}
