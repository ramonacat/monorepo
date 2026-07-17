import {
  useState,
  type ElementType,
  type HTMLAttributes,
  type ReactNode,
} from "react";
import * as css from "./Section.css.ts";
import icons from "../../icons";
import { TextInput } from "../form";

type HeadingLevel = 1 | 2 | 3 | 4 | 5 | 6;

function Heading(
  props: {
    level: HeadingLevel;
    children?: ReactNode;
  } & HTMLAttributes<HTMLHeadingElement>,
) {
  const { level, children, ...headingProps } = props;
  const HeaderTag: ElementType<HTMLAttributes<HTMLHeadingElement>> =
    `h${level}`;

  headingProps.className = `${headingProps.className} ${css.heading}`;
  return <HeaderTag {...headingProps}>{children}</HeaderTag>;
}

export function EditableHeading({
  level,
  text,
  onEdit,
}: {
  level: HeadingLevel;
  text: string;
  onEdit: (text: string) => void;
}) {
  const [editing, setEditing] = useState<boolean>(false);

  if (editing) {
    return (
      <TextInput
        className={`${css.editableHeadingInput} ${css[`editableH${level}`]}`}
        defaultValue={text}
        onChange={(change) => onEdit(change.target.value)}
        onBlur={() => setEditing(false)}
      />
    );
  } else {
    return (
      <Heading
        level={level}
        className={css.editableHeading}
        onClick={() => setEditing(true)}
      >
        {text} <icons.Edit className={css.editIcon} />
      </Heading>
    );
  }
}

export function HeaderNavigation({ children }: { children: ReactNode }) {
  return <div className={css.headerNavigation}>{children}</div>;
}

export function SectionHeader(
  props: {
    headingText: string;
    children?: ReactNode;
    level: HeadingLevel;
    topNavigation?: boolean;
  } & HTMLAttributes<HTMLElement>,
) {
  const {
    headingText,
    children,
    level,
    className,
    topNavigation,
    ...headerProps
  } = props;

  return (
    <header
      className={`${css.sectionHeader} ${topNavigation ? css.sectionHeaderTopNavigation : ""} ${className}`}
      {...headerProps}
    >
      <Heading level={level}>{headingText}</Heading>
      {children}
    </header>
  );
}

export function Section({
  header,
  children,
  contentsClassName = "",
  className = "",
}: {
  header: ReactNode;
  children?: ReactNode | ReactNode[];
  contentsClassName?: string;
  className?: string;
}) {
  return (
    <section className={`${css.section} ${className}`}>
      {header}
      <div className={`${css.contents} ${contentsClassName}`}>{children}</div>
    </section>
  );
}
