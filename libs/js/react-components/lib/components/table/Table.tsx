import type {
  HTMLAttributes,
  ReactNode,
  RefAttributes,
  TdHTMLAttributes,
} from "react";
import * as css from "./Table.css";

export function TableCell({
  children,
  className,
  ref,
  ...props
}: { children?: ReactNode } & TdHTMLAttributes<HTMLTableCellElement> &
  RefAttributes<HTMLTableCellElement>) {
  return (
    <td ref={ref} className={`${className} ${css.td}`} {...props}>
      {children}
    </td>
  );
}

export function TableRow({
  children,
  ...props
}: { children: ReactNode } & HTMLAttributes<HTMLTableRowElement>) {
  return <tr {...props}>{children}</tr>;
}

export function TableBody({
  children,
  className,
  ...props
}: { children: ReactNode } & HTMLAttributes<HTMLTableSectionElement>) {
  return (
    <tbody className={`${className}`} {...props}>
      {children}
    </tbody>
  );
}

export function TableHead({
  children,
  className,
  ...props
}: { children: ReactNode } & HTMLAttributes<HTMLTableSectionElement>) {
  return (
    <thead className={`${className} ${css.thead}`} {...props}>
      {children}
    </thead>
  );
}

export function Table({
  children,
  className,
  ...props
}: { children: ReactNode } & HTMLAttributes<HTMLTableElement>) {
  return (
    <table className={`${className} ${css.table}`} {...props}>
      {children}
    </table>
  );
}
