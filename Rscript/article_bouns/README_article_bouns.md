# 工讀生額外稿費模型

---

設計原因

> 因為只看 view 數無法反映真實的文章質量，view 數會受到 instagram 現實動態和 facebook 紛絲團推廣，以及不同的文章類型而使文章的 view 數會有基數有差別，故本模型是讓文章將干擾變數（文章類型或推廣次數和來源等等）還原為原始的 view 數。

模型原理

1. 將文章推廣的來源（affiliate）分類，分為 IG、FB 和 其他，計算分別在統計期間透過這三個來源所產生的 `session` 來推算不同平台所可以產生的導流效果。並將觀看數乘上該係數讓每篇文章得到一個 `score`，將每篇文章的 `score` 除以推廣次數。
2. 將每位小編和每位小編下面有的帳號（mid）過取所累積的文章分別找出平均 `score`，並將每篇文章的 `score` 減去過去累積所有 `mid` 得到最終分數。
3. 會將最終分數做機率密度模型，將所有的文章標準差相加，並與每個人產出的文章量所呈現的常態分配做比較，能高於本上自有產出文章數量常態分配模型的概略密度函數，即可拿到獎金

如何獲得獎金

> 由於會與自己的過去 mid 所累積的分數比較，故同樣的帳號下，比過去該帳號的表現更好會有更多機會

> 由於會計算變異數，故在同樣的 mid 下文章質量若差距太大則不容易拿到獎金

> 簡言之，大部分在某個 mid 下發的文章大部分要達到該 mid 的平均左右（大約 60%）但需要部份 表現不錯的文章（約 10% － 20%），和少部分的爆文，就容易拿到獎金　



* 藉由獲取文章瀏覽數的渠道，看每個編輯在所有的獲得瀏覽數的比例

![](https://raw.githubusercontent.com/popdaily/popdaily.bigquery/Rdevelop/Rscript/article_bouns/image/Rplot.png?token=AEITWGRJO5ILBNEMFVPMDXK5SSA3S)



* 依照每個編輯的發文帳號與編輯本身的瀏覽數做比較，可看出不同帳號的表現

![](https://raw.githubusercontent.com/popdaily/popdaily.bigquery/Rdevelop/Rscript/article_bouns/image/Rplot01.png?token=AEITWGTMIBZSAR2TBEG2I5C5SSA5O)



* 依照每個編輯經過分數轉換後，文章分數的箱型圖

![](https://raw.githubusercontent.com/popdaily/popdaily.bigquery/Rdevelop/Rscript/article_bouns/image/Rplot02.png?token=AEITWGSYGCQH7GCMI3DYEG25SSBAC)



* 將每個編輯的最終分數轉換為機率密度圖，並與常態分布做比較，產生稿費級距

![](https://raw.githubusercontent.com/popdaily/popdaily.bigquery/Rdevelop/Rscript/article_bouns/image/Rplot03.png?token=AEITWGVQLAFX4IR5H2RPA2K5SSBCO)

