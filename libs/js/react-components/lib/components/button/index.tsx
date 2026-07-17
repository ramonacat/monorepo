import {
  type AnchorHTMLAttributes,
  type ButtonHTMLAttributes,
  type ReactNode,
} from "react";
import { NavLink, type NavLinkProps } from "react-router";
import * as css from "./Button.css.ts";

function mkClassName(hasChildren: boolean, ...other: (string | undefined)[]) {
  const buttonStyle = !hasChildren ? css.buttonIconOnly : css.button;

  return [buttonStyle, ...other.filter((x) => x !== undefined)].join(" ");
}

function Contents({ children }: { children?: ReactNode }) {
  if (children === undefined) {
    return "";
  }
  return (
    <div className={css.contentsContainer}>
      <span className={css.text}>{children}</span>
    </div>
  );
}

export function ButtonLink({
  icon: icon,
  children = undefined,
  ...props
}: NavLinkProps &
  AnchorHTMLAttributes<HTMLAnchorElement> & {
    icon?: ReactNode;
    children?: ReactNode;
  }) {
  const { className, ...restProps } = props;

  return (
    <NavLink
      className={({ isActive }) =>
        mkClassName(
          children !== undefined,
          className,
          isActive ? css.buttonActive : "",
        )
      }
      {...restProps}
    >
      {icon}
      <Contents>{children}</Contents>
    </NavLink>
  );
}

export function Button({
  icon,
  children = undefined,
  className = undefined,
  ...props
}: ButtonHTMLAttributes<HTMLButtonElement> & {
  icon?: ReactNode;
  children?: ReactNode;
}) {
  const mergedProps = {
    ...props,
    className: mkClassName(
      children !== undefined,
      props.type === "submit" ? css.submit : "",
      className,
    ),
  };

  return (
    <button {...mergedProps}>
      {icon}
      <Contents>{children}</Contents>
    </button>
  );
}
