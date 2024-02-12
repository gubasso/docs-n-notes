# Binary Trees

<!-- toc -->

- [LeetCode Problems](#leetcode-problems)
- [Depth-first search (DFS)](#depth-first-search-dfs)
  - [Traverse DFS Recursive](#traverse-dfs-recursive)
  - [Traverse DFS Iterative (Stack)](#traverse-dfs-iterative-stack)

<!-- tocstop -->

## LeetCode Problems

- 104. Maximum Depth of Binary Tree
- 112. Path Sum

## Depth-first search (DFS)

### Traverse DFS Recursive

```js
class TreeNode {
    constructor(val) {
        this.val = val;
        this.left = null;
        this.right = null;
    }
}

let dfs = node => {
  if(!node) {
    return
  }
  // logic when preorder traversal
  dfs(node.left)
  // logic when Inorder traversal
  dfs(node.right)
  // logic when Postorder traversal
  return
}
```

### Traverse DFS Iterative (Stack)

```js
let maxDepth = node => {
  if(!node) {
    return 0;
  }

  let stack = [[root, 1]]
  let ans = 0;

  while(stack.length) {
    const [node, depth] = stack.pop()
    ans = Math.max(ans, depth)
    if(node.left) {
      stack.push([node.left, depth + 1])
    }
    if(node.right) {
      stack.push([node.right, depth + 1])
    }
  }

  return ans
}
```

