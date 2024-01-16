namespace Test

def hello := "world"

theorem thm_1 : 1 + 1 = 2 := sorry
#print axioms thm_1

theorem thm_2 : 1 + 1 = 2 := rfl

theorem thm_3 : 1 + 1 = 2 := by apply thm_1
#print axioms thm_3

end Test
