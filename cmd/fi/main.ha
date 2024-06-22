use bufio;
use fmt;
use os;
use strings;
use path;
use fs;
use io;

export fn main() void = {
	const fpath = match (get_path()) {
	case let s: str =>
	     yield s;
	case let err: fs::error =>
	     fmt::fatalf("fi: {}", fs::strerror(err));
	case nocurdir =>
	     fmt::fatalf("fi: current directory not found");
	};
	match(os::stat(fpath)) {
	case let f: fs::filestat =>
		// just a single file instead of dir
		if (f.mode & fs::mode::DIR == 0) {
			ls(fpath, f);
			return;
		};
	case let err: fs::error =>
	     fmt::fatalf("fi: {}", fs::strerror(err));
	};
	walk_dirs(fpath);
};

fn ls(name: str, f: fs::filestat) void = {
	if (f.mode & fs::mode::DIR > 0) {
		fmt::printf("{:2}", "🗀 ")!;
	} else {
		fmt::printf("{:2}", " ")!;
	};
	fmt::printf("{} {:10} {}\n", display_mode(f.mode), f.sz, name)!;
};

fn walk_dirs(dirpath: str) void = {
	os::chdir(dirpath)!;
	let dirs = match (os::iter(dirpath)) {
	case let it: *fs::iterator =>
	     yield it;
	case let err: fs::error =>
	     fmt::fatalf("fi: {}\n", fs::strerror(err));
	};
	defer fs::finish(dirs);
	for (let dir => fs::next(dirs)) {
		match(dir) {
		case let d: fs::dirent =>
			match(os::stat(d.name)) {
			case let f: fs::filestat =>
				ls(d.name, f);
			case let err: fs::error =>
				fmt::printf("fi: {} ({})\n", fs::strerror(err), d.name)!;
			};
		case let err: fs::error =>
			fmt::printf("fi: {}", fs::strerror(err))!;
		};
	};
};

type nocurdir = !void;
type error = !(nocurdir | fs::error);

fn get_path() (str | error) = {
	let fpath: (str | error) = "": str;
	if (len(os::args) > 1) {
		fpath = os::args[1];
	} else {
		fpath = match (os::getenv("PWD")) {
		case let s: str =>
			yield s;
		case void =>
			yield nocurdir;
		};
	};
	return os::realpath(fpath as str)?;
};

fn display_mode(mode: fs::mode) str = {
	let m = mode;
	let res = "";
	for (let i = 0z; i < 3; i += 1) {
		switch (m & 0b111) {
		case fs::mode::OTHER_RWX => res = strings::concat("☷", res);
		case fs::mode::OTHER_RW => res = strings::concat("☳", res);
		case fs::mode::OTHER_RX => res = strings::concat("☵", res);
		case 0b011 => res = strings::concat("☶", res); // OTHER_WX is absent in lib
		case fs::mode::OTHER_R => res = strings::concat("☱", res);
		case fs::mode::OTHER_W => res = strings::concat("☲", res);
		case fs::mode::OTHER_X => res = strings::concat("☴", res);
		case => res = strings::concat("☰", res);
		};
		m = m >> 3;
	};
	return res;
};
		//		 .{ 0b000, "☰" }, // ---
    // .{ 0b001, "☴" }, // --x
    // .{ 0b010, "☲" }, // -w-
    // .{ 0b011, "☶" }, // -wx
    // .{ 0b100, "☱" }, // r--
    // .{ 0b101, "☵" }, // r-x
    // .{ 0b110, "☳" }, // rw-
    //	.{ 0b111, "☷" }, // rwx
