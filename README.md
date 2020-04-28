# An Relational Optimizer and Executor Modeling
This project models a relational optimizer and executor in c#. The purpose of the modeling is to prepare for a more serious implementation of database optimizer and execution. See github project "issues" for bugs and todo items.

## Why C#
The major target is optimizer and it is logic centric, so it a high level language needed. After modeling, production may want to turn it into some C/C++ code, so the language has to be a close relative of C/C++.  C# provides some good features like LINQ, dynamic types to make modeling easy, and it is close enough to C++ (and that's why not python).

## Optimizer
The optimizer exercise following constructs:
- Top down/bottom up structure: the optimizer does utilize a top down cascades style optimizer structure but optionally you can choose to use bottom up join order resolver.  It currently use DPccp (["Analysis of Two Existing and One New Dynamic Programming Algorithm"](http://www.vldb.org/conf/2006/p930-moerkotte.pdf)) by G. Moerkotte, et al. It also implments some other join order resolver like DPBushy (TDBasic, GOO), mainly for the purpose of correctness verification. A more generic join resolver DPHyper ([Dynamic Programming Strikes Back](https://15721.courses.cs.cmu.edu/spring2017/papers/14-optimizer1/p539-moerkotte.pdf)) is in preparation. 
- Subquery decorrelation: it follows the ["Unnesting Arbitrary Queries"](https://pdfs.semanticscholar.org/1596/d282b7b6e8723a9780a511c87481df070f7d.pdf) and ["The Complete Story of Joins (in Hyper)"](http://btw2017.informatik.uni-stuttgart.de/slidesandpapers/F1-10-37/paper_web.pdf) by T. Neumann et al. 
- CTE inline/noninline (ongoing): it follows the [Optimization of Common Table Expressions in MPP Database Systems](http://www.vldb.org/pvldb/vol8/p1704-elhelw.pdf) by A. El-Helw et al.
- Cardinality estimation, costing: currently this follows "as-is" text book implementation. We didn't spend much time here because it is a local issue, meaning later improvements shall not impact the architecture. CE also demonstrate upgrade or version management.
- The optimizer also expose a DataSet like interface which demonstrates language intergration. Another example calculating Pi with Monte-Carlo can be found in Unittest/TestDataSet.
```c#
	SQLContext sqlContext = new SQLContext();

	// leverage c#'s sqrt so we don't have to write our own
	double sqroot(double d) => Math.Sqrt(d);
	SQLContext.Register<double, string>("sqroot", sqroot);

	// use sqroot in SQL
	var sql = "SELECT a1, sqroot(b1*a1+2) from a join b on b2=a2 where a1>1";

	// above query in DataSet form
	var a = sqlContext.Read("a");
	var b = sqlContext.Read("b");
	var rows = a.filter("a1>1").join(b, "b2=a2").select("a1", "sqroot(b1*a1+2)").show();
```
- Verify the optimizer by some unittests and TPCH/DS. All TPCH queries are runnable. TPCDS we don't support window function and rolling groups. You can find TPCH plan [here](https://github.com/zhouqingqing/adb/tree/master/test/regress/expect/tpch0001).

## Executor
The executor is implemented for two purpose: (1) verify plan correctness; (2) demonstrate callback style codeGen engineering readiness following paper ["How to Architect a query compiler, Revisited"](https://www.cs.purdue.edu/homes/rompf/papers/tahboub-sigmod18.pdf) by R.Y.Tahboub et al. Executor is not intented to  demonstrate implmenting specific operator efficiently.
- It does't use a LMS underneath, but thanks for c#'s interpolated string support, the template is easy to read and construct side by side with interpreted code.
- To support incremental codeGen improvement, meaning we can ship partial codeGen implmenetation, it supports a generic expression evaluation function which can fallback to the interpreted implementation if that specific expression is not codeGen ready.
- The executor utilizes Object and dynamic types to simplify implementation. To port it to C/C++, you can follow the traditional "dispatch" mechanism like a + b => {int4pl(a,b), int2pl(a,b), doublepl(a,b), ...}.

You can see an example generated code for this query [here](https://github.com/zhouqingqing/adb/tree/master/test/gen_example.cs) with generic expression evaluation is in this code snippet:

```c#
	// projection on PhysicHashAgg112: Output: {a.a2}[0]*2,{count(a.a1)}[1],repeat('a',{a.a2}[0]) 
	Row rproj = new Row(3);
	rproj[0] = ((dynamic)r112[0] * (dynamic)2);
	rproj[1] = r112[1];
	rproj[2] = ExprSearch.Locate("74").Exec(context, r112) /*repeat('a',{a.a2}[0])*/;
	r112 = rproj;
```

## How to Play
Load the project with Visual Studio 2019 community version. Program.Main() mainly for debugging purpose. So run unnitest project. The unittest come up with multiple tests:
- TPCH with small data set
- TPCDS, JoBench only exercise the optimizer
- Other grouped unittest
