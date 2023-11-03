# Algorithms

<!-- toc GFM -->

+ [Trees and Graphs](#trees-and-graphs)
+ [Recursive Functions](#recursive-functions)
+ [Binary Search](#binary-search)
+ [GCD (great common denominator) and LCM (least common multiplier)](#gcd-great-common-denominator-and-lcm-least-common-multiplier)
+ [KMP Knuth-Morris-Pratt](#kmp-knuth-morris-pratt)
+ [Breadth First Search (BFS) Algorithm](#breadth-first-search-bfs-algorithm)
+ [References:](#references)

<!-- toc -->

- [Trees and Graphs](#trees-and-graphs)
  - [DFS:](#dfs)
- [Recursive Functions](#recursive-functions)
- [Binary Search](#binary-search)
- [GCD (great common denominator) and LCM (least common multiplier)](#gcd-great-common-denominator-and-lcm-least-common-multiplier)
- [KMP Knuth-Morris-Pratt](#kmp-knuth-morris-pratt)
- [Breadth First Search (BFS) Algorithm](#breadth-first-search-bfs-algorithm)
- [References:](#references)

<!-- tocstop -->

# Trees and Graphs

- DFS: easier with recursive functions
- BFS: easier with iterative functions

Both can be used because both runs throw the entire tree.

BFS vs DFS, such as their **drawbacks**

"The main disadvantage of DFS is that you could end up wasting a lot of time looking for a value. Let's say that you had a huge tree, and you were looking for a value that is stored in the root's right child. If you do DFS prioritizing left before right, then you will search the entire left subtree, which could be hundreds of thousands if not millions of operations. Meanwhile, the node is literally one operation away from the root. The main disadvantage of BFS is that if the node you're searching for is near the bottom, then you will waste a lot of time searching through all the levels to reach the bottom."

"In terms of space complexity, if you have a complete binary tree, then the amount of space used by the recursive call stack for DFS is linear with the height, which is logarithmic with n (the number of nodes). The amount of space used by the queue is linear with n, so DFS has a much better space complexity. The reason the queue will grow linearly is because the final level in a complete binary tree can have up to n/2 nodes.

However, if you have a lopsided tree (like a straight line), then BFS will have an O(1)O(1) space complexity while DFS will have O(n)O(n) (although, a lopsided tree is an edge case whereas a full tree is the expectation)."

- DFS:
    -

# Recursive Functions

[How to write Recursive Functions](https://www.youtube.com/watch?v=ggk7HbcnLG8)

**Basic Structure**
```
func()
{
  if(  )
  {
    // base case (2)
  }
  else
  {
    // recursive procedure (1)
  }
}
```

(1) First write recursive procedure
(2) Then write the base case

Step 1) Divide the problem into smaller sub-problems

```
Calculate the factorial(4)

Fact(1) = 1;
Fact(2) = 2 * 1 = 2 * Fact(1);
Fact(3) = 3 * 2 * 1 = 3 * Fact(2);
Fact(4) = 4 * 3 * 2 * 1 = 4 * Fact(3);
```

- Begin with the simplest cases

```
Fact(n) = n * Fact(n-1)
```

```
Fact(int n)
{
  if(  )
  {
    // base case (2)
  }
  else
  {
    return n * Fact(n-1);
  }
}
```

Step 2) Specify the base condition to stop the recursion

```
Fact(1) = 1
```

```
Fact(int n)
{
  if( n == 1 )
  {
    return 1;
  }
  else
  {
    return n * Fact(n-1);
  }
}
```



# Binary Search

- [Construct a complete binary tree from given array in level order fashion](https://www.geeksforgeeks.org/construct-complete-binary-tree-given-array/)

- [Good Binary Search Problems](https://leetcode.com/problems/minimum-time-to-complete-trips/solutions/3266855/all-binary-search-problems/)

"In this type of questions (where question want some minimum/ maximum / at least ) we use concept of Binary search"[^1]

# GCD (great common denominator) and LCM (least common multiplier)

- [C++ code to find LCM of two numbers | Geeksforgeeks](https://www.youtube.com/watch?v=anSfYgbo694)
  - clean gcd implementation
  - relation between gcd and lcm
- [Program to find GCD 0f 2 numbers and GCD of N numbers or GCD of an Array](https://www.youtube.com/watch?v=Gr9gtrXvHqU)

- [Program To Calculate LCM Of Two Numbers | Python Tutorials](https://www.youtube.com/watch?v=6ykRY6bHVX0)

# KMP Knuth-Morris-Pratt

!!! [Knuth-Morris-Pratt (KMP) algorithm | String Matching Algorithm | Substring Search](https://www.youtube.com/watch?v=4jY57Ehc14Y)
[Knuth–Morris–Pratt KMP - Find the Index of the First Occurrence in a String - Leetcode 28 - Python](https://www.youtube.com/watch?v=JoF0Z7nVSrA)

- String matchin
- O(n+m)

# Breadth First Search (BFS) Algorithm

[Breadth First Search Algorithm | Shortest Path | Graph Theory](https://www.youtube.com/watch?v=oDqjPvD54Ss)
[5.1 Graph Traversals - BFS & DFS -Breadth First Search and Depth First Search](https://www.youtube.com/watch?v=pcKY4hjDrxk)

- objective: find the shortest path on unweighted graphs

- time complexity: O(v+e) (vertices + edges)

explores nodes in layer:
- start node: explore neighbours (1 layer)
- neighbours (1): explores their neighbours (2)
- neighbours (2): ...

- can be used to convert/transform a tree/graph to an array/vector
    - `convert_tree_node_to_vec` at leetcode `p226_invert_binary_tree`

# References:

[^1]: [2187. Minimum Time to Complete Trips - C++| Answer on Binary Search | List of Related Problem](https://leetcode.com/problems/minimum-time-to-complete-trips/solutions/1802416/c-answer-on-binary-search-list-of-related-problems/)
