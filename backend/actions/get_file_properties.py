import sys
import stat
import pwd
import grp
from pathlib import Path
from datetime import datetime
from models import ActionDef, ActionInput, ActionOutput

def file_info(path_str):
    p = Path(path_str).expanduser()
    info = {"path": str(p), "exists": p.exists()}

    if not info["exists"]:
        # lexists catches broken symlinks
        info["broken_symlink"] = p.is_symlink()
        return info

    st = p.lstat()  # lstat = don't follow symlink; use .stat() to follow

    info.update({
        "type": (
            "dir" if p.is_dir() else
            "file" if p.is_file() else
            "symlink" if p.is_symlink() else
            "other"
        ),
        "is_symlink": p.is_symlink(),
        "size_bytes": st.st_size,
        "permissions_octal": oct(stat.S_IMODE(st.st_mode)),
        "permissions_str": stat.filemode(st.st_mode),
        "owner_uid": st.st_uid,
        "group_gid": st.st_gid,
        "modified_time": datetime.fromtimestamp(st.st_mtime).isoformat(),
        "accessed_time": datetime.fromtimestamp(st.st_atime).isoformat(),
        "created_or_meta_changed": datetime.fromtimestamp(st.st_ctime).isoformat(),
        "inode": st.st_ino,
        "hardlink_count": st.st_nlink,
        "absolute_path": str(p.resolve()),
    })

    # owner/group names (unix only, may fail)
    try:
        info["owner_name"] = pwd.getpwuid(st.st_uid).pw_name
        info["group_name"] = grp.getgrgid(st.st_gid).gr_name
    except (KeyError, ImportError):
        pass

    if p.is_symlink():
        info["symlink_target"] = str(p.readlink())

    return info

def _run(inputs: dict, context: dict):
    path = inputs["path"]
    info = file_info(path)
    return info


ACTION = ActionDef(
    id="filesystem.get_file_properties",
    category="Filesystem",
    name="Get file properties",
    description="Reads the properties of a file or directory.",
    icon="files",
    color="red",
    platforms=["linux", "windows"],
    inputs=[
        ActionInput(name="path", type="path", label="Path", required=True, tooltip="The path of the file or directory to get properties for. Use ~ to refer to the home directory."),
    ],
    outputs=[
        ActionOutput(name="type", type="string", label="Type (dir, file, symlink, other)"),
        ActionOutput(name="is_symlink", type="boolean", label="Is Symlink"),
        ActionOutput(name="size_bytes", type="number", label="Size (bytes)"),
        ActionOutput(name="permissions_string", type="string", label="Permissions"),
        ActionOutput(name="owner_uid", type="number", label="Owner UID"),
        ActionOutput(name="group_gid", type="number", label="Group GID"),
        ActionOutput(name="modified_time", type="string", label="Time Modified"),
        ActionOutput(name="accessed_time", type="string", label="Time Accessed"),
        ActionOutput(name="created_or_meta_changed", type="string", label="Time Created or Metadata Changed"),
        ActionOutput(name="inode", type="number", label="Inode"),
        ActionOutput(name="hardlink_count", type="number", label="Hardlink Count"),
        ActionOutput(name="absolute_path", type="path", label="Absolute Path"),
    ],
    run=_run,
)
