import { useEffect, useRef, type ReactNode } from "react";
import * as css from "./Modal.css.ts";
import { Section, HeaderNavigation, SectionHeader } from "../section";
import icons from "../../icons";
import { Button } from "../button";

export default function Modal({
  isOpen,
  headingText: headingText,
  children,
  onClose,
}: {
  isOpen?: boolean;
  headingText: string;
  children?: ReactNode | ReactNode[];
  onClose?: () => void;
}) {
  const dialogRef = useRef<HTMLDialogElement>(null);

  useEffect(() => {
    if (dialogRef.current === null) {
      return;
    }

    dialogRef.current.addEventListener("close", () => onClose?.());

    if (isOpen) {
      dialogRef.current.showModal();
    } else {
      dialogRef.current.close();
    }
  }, [isOpen, dialogRef]);

  return (
    <dialog ref={dialogRef} className={css.dialog}>
      <Section
        header={
          <SectionHeader level={2} headingText={headingText}>
            <HeaderNavigation>
              <Button
                icon={<icons.Close className={css.closeIcon} />}
                onClick={() => dialogRef.current?.close()}
              />
            </HeaderNavigation>
          </SectionHeader>
        }
        className={css.section}
        contentsClassName={css.sectionContents}
      >
        {children}
      </Section>
    </dialog>
  );
}
