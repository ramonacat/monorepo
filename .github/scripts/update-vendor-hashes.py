from io import SEEK_SET
import os
import subprocess
import re
from subprocess import CompletedProcess
from glob import glob
from typing import Callable

def find_hash_in_output(lines: list[str]) -> str|None:
    new_hash_list = [x for x in lines if x.find("got:") != -1];

    if len(new_hash_list) == 0:
      return None

    new_hash_line = new_hash_list[0]
    new_hash = re.match('^.*got:\\s*(.*)\\s*.*$', new_hash_line)

    if new_hash is None:
        return None

    return new_hash.group(1)

def find_hash_in_file(lines: list[str]) -> str|None:
    # r'^(?P<before>.*vendorHash\s*=\s*").*?(?P<after>".*)$'
    new_hash_list = [x for x in lines if x.find("vendorHash") != -1];
    if len(new_hash_list) == 0:
        return None

    new_hash_line = new_hash_list[0]
    new_hash = re.match(r'^(?P<before>.*vendorHash\s*=\s*")(?P<hash>.*?)(?P<after>".*)$', new_hash_line)

    if new_hash is None:
        return None

    return new_hash.group('hash')


def replace_in_file(path: str, replacement: Callable[[str], str]):
    with open(path, 'r+') as file:
        new_contents = replacement(file.read())
        _ = file.seek(0, SEEK_SET)
        _ = file.write(new_contents)
        _ = file.truncate()

changed_files: CompletedProcess[bytes] = subprocess.run(['git', 'diff', '--name-only', f"origin/{os.getenv("GITHUB_BASE_REF")}"], capture_output=True)
changed_apps = [app.decode('utf-8').split('/')[1] for app in changed_files.stdout.splitlines() if app.startswith(b'apps/')]

for app in changed_apps:
    nix_files_to_check = [f'packages/{app}.nix'] if os.path.isfile(f'packages/{app}.nix') else glob(f'packages/{app}/**.nix', recursive=True);
    print(f"checking {app}: {nix_files_to_check}")

    for path in nix_files_to_check:
        print(f"refreshing hash in {path}")
        with open(path, 'r+') as file:
            current_hash = find_hash_in_file(file.readlines())

        if current_hash is None:
            print("no hash found")

            continue

        replace_in_file(path, lambda x: x.replace(current_hash, ""))

        output = subprocess.run(['nix', 'build', f'.#packages.x86_64-linux.{app}'], capture_output=True)
        output = output.stderr.decode('utf-8')

        new_hash = find_hash_in_output(output.splitlines())


        if new_hash is None:
            print("no match")
            new_hash = current_hash

        replace_in_file(path, lambda x: re.sub(r'^(?P<before>.*vendorHash\s*=\s*").*?(?P<after>".*)$', f'\\g<before>{new_hash}\\g<after>', x, flags=re.MULTILINE))
