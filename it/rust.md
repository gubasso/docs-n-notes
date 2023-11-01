# Rust Programming Language
> $rust $rust-lang

<!-- toc -->

# cargo release

- release workflow: https://github.com/nextest-rs/nextest/blob/main/internal-docs/releasing.md

# `git2` crate (`libgit2`)

example of commit:

```rust
pub fn git_commit(files_to_add: Option<&[String]>, msg: &str) -> Result<()> {
    let repo = Repository::open(".").with_context(|| "failed to open repository")?;
    let signature = repo.signature()?;
    let mut index = repo.index()?;
    if let Some(files_to_add) = files_to_add {
        index.add_all(files_to_add.iter(), IndexAddOption::DEFAULT, None)?;
    }
    index.write()?;
    let oid = index.write_tree()?;
    let tree = repo.find_tree(oid)?;
    let head = repo.head()?;
    let ref_name = head.name();
    let parent_commit_res = head.peel_to_commit();
    let parent_commit = if parent_commit_res.is_ok() {
        vec![parent_commit_res.as_ref().unwrap()]
    } else {
        vec![]
    };

    repo.commit(ref_name, &signature, &signature, msg, &tree, &parent_commit)?;
    Ok(())
}
```

# Tests

substitute / alternative for native cargo test:

https://nexte.st/book/installation.html

# Modules / File / Dir structure

- [Media: How to create a module hierarchy in Rust (improved version) ](https://www.reddit.com/r/rust/comments/ujry0b/media_how_to_create_a_module_hierarchy_in_rust/)
    - [Chart](https://www.reddit.com/media?url=https%3A%2F%2Fi.redd.it%2Fmedia-how-to-create-a-module-hierarchy-in-rust-improved-v0-1yy98srxyvx81.png%3Fs%3Dc42117fd2140c83562936948de3441fe29f95559)

# Arrays / Vectors

avoid array index out of bounds

basic brute example:
```
for i in points.len() {
  let current = points[i];
  let previous = points[i-1];
  differences.push(current-previous);
}
```

with array_windows
```
for [previous, current] in points.array_windows().copied() {
  differences.push(current-previous);
}

# or

let differences: Vec<_> = points
  .array_windows()
  .copied()
  .map(|[previous, current]| current - previous)
  .collect;
```

# Iterators

Save a range iterator and/or reversed range to the same variable (e.g. when you want to apply some conditional)

```rust
let iter = if level % 2 != 0 {
    Box::new(0..len) as Box<dyn Iterator<Item = _>>
} else {
    Box::new((0..len).rev())
};

for j in iter {
    // do something
}
```

Iterate over leafs/nodes:

```rust
// immutably
for leaf in [&node.left, &node.right] {
    if let Some(nd) = leaf {
        queue.push_back(Rc::clone(nd));
    }
}
// immutably: same as above
for leaf in [&node.left, &node.right].into_iter().flatten() {
    queue.push_back(Rc::clone(leaf));
}

// mutably, with Index/IndexMut
use std::ops::{Index,IndexMut};
impl Index<usize> for TreeNode {
    type Output = Option<Rc<RefCell<TreeNode>>>;
    fn index(&self, index: usize) -> &Self::Output {
        match index {
            0 => &self.left,
            1 => &self.right,
            n => panic!("Invalid TreeNode index: {}", n)
        }
    }
}

impl IndexMut<usize> for TreeNode {
    fn index_mut(&mut self, index: usize) -> &mut Option<Rc<RefCell<TreeNode>>> {
        match index {
            0 => &mut self.left,
            1 => &mut self.right,
            n => panic!("Invalid TreeNode index: {}", n)
        }
    }
}

for j in 0..2 {
    i += 1;
    if let Some(&Some(val)) = vec.get(i) {
        let new_node = Rc::new(RefCell::new(TreeNode::new(val)));
        node.borrow_mut()[j] = Some(Rc::clone(&new_node));
        queue.push_back(new_node)
    }
}
```

[In Rust, is there a way to iterate through the values of an enum?](https://stackoverflow.com/questions/21371534/in-rust-is-there-a-way-to-iterate-through-the-values-of-an-enum)

working with enums: [A Gentle Introduction To Rust: 2. Structs, Enums and Matching](https://stevedonovan.github.io/rust-gentle-intro/2-structs-enums-lifetimes.html#simple-enums)

# General

Return the type of a variable as a string.

```rust
use std::any::type_name;

fn type_of<T>(_: T) -> &'static str {
    type_name::<T>()
}
```

- list of usefull crates: blessed.rs

- error handling crates:
    - thiserror
    - anyhow

- continuous integration / delivery with rust:
    - 5 Better ways to code in Rust https://www.youtube.com/watch?v=BU1LYFkpJuk

console output in `println!` (std out)
https://stackoverflow.com/questions/25106554/why-doesnt-println-work-in-rust-unit-tests

```
cargo test -- --nocapture

cargo test -p p997_find_the_town_judge -- --nocapture --test-threads 1

cargo clippy --package p909_snakes_and_ladders

```

[Sorting Vector of vectors of f64](https://users.rust-lang.org/t/sorting-vector-of-vectors-of-f64/16264)
```
use std::cmp::Ordering;

fn main() {
    let mut items = vec![4.5, 11.5, -7.3, 14.0, 18.7, 11.5, 1.3, -2.1, 33.7];
    println!("{:?}", items);
    items.sort_by(cmp_f64);
    println!("{:?}", items);
}

fn cmp_f64(a: &f64, b: &f64) -> Ordering {
    if a < b {
        return Ordering::Less;
    } else if a > b {
        return Ordering::Greater;
    }
    return Ordering::Equal;
}
```

creating an iterator from scratch: [Creating an Iterator in Rust](https://aloso.github.io/2021/03/09/creating-an-iterator)

## Study

exercism.io lesson:

The problem with the generic approach on the value is that it must work with both numeric and string values in the tests, which is impractical, as strings aren't inherently even or odd. Also, the tests specify to choose "even-positioned items from the iterator", not even values.

If wanting to constrain a type to numeric types, you might find this SO thread to have some good advice.
https://stackoverflow.com/questions/37296351/is-there-any-trait-that-specifies-numeric-functionality


## Resoures

**https://github.com/mre/idiomatic-rust**

https://cfsamson.github.io/books-futures-explained/
https://web.archive.org/web/20200808120044/https://stjepang.github.io/
read in sequence and then:
https://web.archive.org/web/20200511234503/https://stjepang.github.io/2020/01/25/build-your-own-block-on.html
https://web.archive.org/web/20200207092849/https://stjepang.github.io/2020/01/31/build-your-own-executor.html
https://rust-lang.github.io/async-book/
parei: https://rust-lang.github.io/async-book/02_execution/04_executor.html
depois que ler (tentar implementar esse capitulo), voltar no anterior que ele explica o futures, antes de mostrar o executor
https://cfsamson.gitbook.io/green-threads-explained-in-200-lines-of-rust/
https://cfsamson.github.io/book-exploring-async-basics/
https://cfsamsonbooks.gitbook.io/epoll-kqueue-iocp-explained/

- [Awesome Rust](https://awesome-rust.com/)
    - A curated list of awesome Rust frameworks, libraries and software.

- [Awesome Rust Streaming](https://github.com/jamesmunns/awesome-rust-streaming/blob/master/README.md)
    - This is a community curated list of livestreams about the programming language Rust.

CIS 198: Rust Programming University of Pennsylvania https://cis198-2016s.github.io/schedule/
pure practice:
Rust by example
parei: https://doc.rust-lang.org/rust-by-example/primitives.html

later:
https://github.com/mre/idiomatic-rust
https://rust-lang-nursery.github.io/rust-cookbook/ (snippets to common solution, as import csv)
https://github.com/brson/stdx (list of best crates)


Learning Rust With Entirely Too Many Linked Lists: https://rust-unofficial.github.io/too-many-lists/
The Book
Reading: Programming Rust
examples: github.com/programmingrust


review and redo my `notes` project at gitlab
new_temp_notes, Download


practice: Code examples and exercises
github.com/programmingrust
