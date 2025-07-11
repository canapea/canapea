
function map(fn) {
  const sentinel = {};
  return function transducer(rf) {
    return function mapTransducerHelp(result = sentinel, input = sentinel) {
      // We want only the version with an initial value so arity0 is not needed
      // if (result === sentinel && input === sentinel) {
      //   // Init (ary 0)
      //   // call rf init once to start the process
      //   const value = rf();
      //   const transformed = fn(value);
      //   console.log("....init(ary0)", transformed, "<~", value)
      //   return transformed;
      // } else if (result !== sentinel && input !== sentinel) {
      if (result !== sentinel && input !== sentinel) {
        // Step (ary2 aka reduce)
        // call rf step 0+ times, map exactly once, filter at most once
        const value = fn(input);
        console.log("map: ...|step(ary2)", value, "<~", input)
        return rf(result, value);
      } else if (result !== sentinel && input === sentinel) {
        // Completion (ary 1)
        // must call rf completion exactly once, produces final value
        // or flushes state
        console.log("map: ...|completion(ary1):", result);
        const flushed = rf(result);
        console.log("map: ...|  <~ flushed:", flushed);
        return flushed;
      } else {
        throw "This should never happen!";
      }
    };
  };
}

function filter(predicate) {
  const sentinel = {};
  return function transducer(rf) {
    return function filterTransducerHelp(result = sentinel, input = sentinel) {
      if (result !== sentinel && input !== sentinel) {
        // Step (ary2 aka reduce)
        // call rf step 0+ times, map exactly once, filter at most once
        console.log("filter: ...|step(ary2)", input)
        if (predicate(input)) {
          console.log("filter: .....|predicate(", input, ") === true");
          const value = rf(result, input)
          console.log("filter: .....|  <~", value);
          return value;
        }
        console.log("filter: .....|predicate(", input, ") === false");
        return result;
      } else if (result !== sentinel && input === sentinel) {
        // Completion (ary 1)
        // must call rf completion exactly once, produces final value
        // or flushes state
        console.log("filter: ...|completion(ary1)", result);
        return rf(result);
      }
      throw "filter: This should never happen!";
    };
  };
}

function take(count) {
  const sentinel = {};
  return function transducer(rf, k = 1) {
    return function takeTransducerHelp(result = sentinel, input = sentinel) {
      if (result !== sentinel && input !== sentinel) {
        // Step (ary2 aka reduce)
        // call rf step 0+ times, map exactly once, filter at most once
        console.log("take: ...|step(ary2)", input)
        if (k <= count) {
          console.log("take: .....|", k, "<=", count);
          k += 1;
          const value = rf(result, input)
          console.log("take: .....|  <~", value);
          return value;
        }
        console.log("take: .....|", k, ">", count);
        return [result, "reduced"];
      } else if (result !== sentinel && input === sentinel) {
        // Completion (ary 1)
        // must call rf completion exactly once, produces final value
        // or flushes state
        console.log("filter: ...|completion(ary1)", result);
        return rf(result);
      }
      throw "filter: This should never happen!";
    };
  };
}

function lessThanInclusive(max) {
  const sentinel = {};
  return function transducer(rf) {
    return function lessThanInclusiveTransducerHelp(result = sentinel, input = sentinel) {
      if (result !== sentinel && input !== sentinel) {
        // Step (ary2 aka reduce)
        // call rf step 0+ times, map exactly once, filter at most once
        console.log("lessThan: ...|step(ary2)", input)
        if (input <= max) {
          console.log("lessThan: .....|", input, "<=", max);
          const value = rf(result, input)
          console.log("lessThan: .....|  <~", value);
          return value;
        }
        console.log("lessThan: .....|", input, ">", max);
        return [result, "reduced"];
      } else if (result !== sentinel && input === sentinel) {
        // Completion (ary 1)
        // must call rf completion exactly once, produces final value
        // or flushes state
        console.log("filter: ...|completion(ary1)", result);
        return rf(result);
      }
      throw "filter: This should never happen!";
    };
  };
}

function compose(f, g) {
  return (x) => f(g(x));
}

function transduce(coll, init, xform, f) {
  if (coll.length === 0) {
    return init;
  }
  const applied = xform(f);
  function transduceStep(acc, value) {
    console.log("....transduceStep(", acc, value, ")")
    return applied(acc, value)
  }
  console.log("transduce", "applied:", applied);
  let acc = init;
  loop: for (let i = 0, len = coll.length; i < len; i += 1) {
    const value = coll[i];
    console.log("..transduce(", "acc:", acc, "value:", value, ")");
    const transformed = transduceStep(acc, value);
    console.log("..transduce", transformed, "<~", "acc:", acc, "value:", value);

    const [res, marker] = Array.isArray(transformed)
      ? transformed
      : [transformed, null];
    acc = res;

    if (marker === "reduced") {
      console.log("..transduce", marker, "<~", res);
      break loop;
    }
  }
  return transduceStep(acc);
}

const idXf = map(x => x);
const addOneXf = map(x => x + 1);
const evensXf = filter(x => x % 2 === 0);
const take3Xf = take(3);
const lessThanEq3Xf = lessThanInclusive(3);
const sum = (acc, value = 0) => {
  console.log("sum: ........sum(", acc, value, ")");
  const result = acc + value;
  console.log("sum: ........  <~", result);
  return result;
};
const concat = (acc, value = []) => {
  return acc.concat(value);
};
const xf = compose(addOneXf, lessThanEq3Xf);
const list = [1, 2, 3, 4, 5];
const init = 0;
console.log("input", list, init);
const result = transduce(list, init, xf, sum);
console.log("result", result);
