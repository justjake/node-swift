const { nums, str, add, rect, getSharableContent } = require("./.build/Module.node");
console.log(nums); // [ 3, 4 ]
console.log(str); // NodeSwift! NodeSwift! NodeSwift!
console.log(rect, rect.origin, rect.size);
// add(5, 10).then(console.log); // 5.0 + 10.0 = 15.0

getSharableContent().then(res => console.log('sharable', res))
