class FilterByName extends Filter{
    private String[] name;
    //int i=0;
    public FilterByName(String... name) {
        this.name = name;
    }
    public boolean accept(Song music) {
        for(int i=0;i<name.length;i++){
            if(name[i].contains(music.getName())){
                return true;
            }
        }
        return false;
    }
}